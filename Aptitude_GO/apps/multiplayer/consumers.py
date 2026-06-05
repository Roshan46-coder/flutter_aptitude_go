import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.utils import timezone
import asyncio

class MatchmakingConsumer(AsyncWebsocketConsumer):
    # Class-level dictionary to hold searching users per topic
    # Format: { 'topic_name': { 'user_id': {'channel_name': '...', 'user': user_obj} } }
    search_queues = {}

    async def connect(self):
        self.user = self.scope["user"]
        if self.user.is_anonymous:
            await self.close()
            return
            
        await self.accept()

    async def disconnect(self, close_code):
        if hasattr(self, 'topic') and self.topic:
            await self.remove_from_queue()

    async def receive(self, text_data):
        data = json.loads(text_data)
        action = data.get('action')

        if action == 'search_match':
            self.topic = data.get('topic')
            
            # Check requirements (coins/lives) first
            has_resources = await self.check_resources()
            if not has_resources:
                await self.send(text_data=json.dumps({
                    'type': 'error',
                    'message': 'Insufficient coins (20) or lives (1) required to play.'
                }))
                return

            await self.add_to_queue()
            
            # Start matchmaking loop task
            self.matchmaking_task = asyncio.create_task(self.matchmaking_loop())

        elif action == 'cancel_search':
            if hasattr(self, 'matchmaking_task'):
                self.matchmaking_task.cancel()
            await self.remove_from_queue()
            await self.send(text_data=json.dumps({
                'type': 'search_cancelled'
            }))

    async def add_to_queue(self):
        if self.topic not in MatchmakingConsumer.search_queues:
            MatchmakingConsumer.search_queues[self.topic] = {}
        
        MatchmakingConsumer.search_queues[self.topic][self.user.id] = {
            'channel_name': self.channel_name,
            'user': self.user
        }

    async def remove_from_queue(self):
        if self.topic in MatchmakingConsumer.search_queues and self.user.id in MatchmakingConsumer.search_queues[self.topic]:
            del MatchmakingConsumer.search_queues[self.topic][self.user.id]

    async def matchmaking_loop(self):
        start_time = timezone.now()
        timeout = 30 # seconds
        print(f"[{self.user.username}] Started matchmaking loop for topic {self.topic}")
        
        try:
            while (timezone.now() - start_time).total_seconds() < timeout:
                try:
                    match_found = await self.try_matchmaking()
                    if match_found:
                        print(f"[{self.user.username}] Match found!")
                        return # Exit loop, try_matchmaking handles notification
                except Exception as e:
                    print(f"[{self.user.username}] Error in try_matchmaking: {e}")
                    import traceback
                    traceback.print_exc()
                await asyncio.sleep(2) # Poll every 2 seconds
            
            # Timeout reached
            print(f"[{self.user.username}] Matchmaking timeout reached.")
            await self.remove_from_queue()
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'No opponent found. Try again later!'
            }))
        except asyncio.CancelledError:
            print(f"[{self.user.username}] Matchmaking cancelled.")
            pass
            
    async def try_matchmaking(self):
        queue = MatchmakingConsumer.search_queues.get(self.topic, {})
        
        # Remove ourselves to find opponent
        candidates = [uid for uid in queue if uid != self.user.id]
        
        # Extensive diagnostic logging
        print(f"[{self.user.username}] try_matchmaking check:")
        print(f"  Topic: {self.topic}")
        print(f"  All queues: {list(MatchmakingConsumer.search_queues.keys())}")
        print(f"  Users in this topic's queue: {list(queue.keys())}")
        print(f"  Valid Candidates: {candidates}")

        if candidates:
            # Basic FCFS matchmaking
            opponent_id = candidates[0]
            opponent_data = queue[opponent_id]
            
            # We have a match!
            print(f"[{self.user.username}] Found opponent! Player: {self.user.username}, Opponent: {opponent_data['user'].username}")

            # 1. Remove both from queue (safely using pop to avoid KeyError if already removed)
            MatchmakingConsumer.search_queues[self.topic].pop(self.user.id, None)
            MatchmakingConsumer.search_queues[self.topic].pop(opponent_id, None)
            
            # 2. Create Match in DB and deduct resources
            match_id = await self.create_match_and_deduct(opponent_data['user'])
            if not match_id:
                # Resource deduction failed, put opponent back
                MatchmakingConsumer.search_queues[self.topic][opponent_id] = opponent_data
                await self.send(text_data=json.dumps({
                    'type': 'error',
                    'message': 'Failed to create match due to insufficient resources.'
                }))
                print(f"[{self.user.username}] Match creation failed due to resources.")
                return True # Stop polling
            
            # 3. Notify both users
            match_data_for_p1 = {
                'type': 'match_found',
                'match_id': match_id,
                'opponent': {
                    'id': opponent_data['user'].id,
                    'username': opponent_data['user'].username,
                }
            }
            match_data_for_p2 = {
                'type': 'match_found',
                'match_id': match_id,
                'opponent': {
                    'id': self.user.id,
                    'username': self.user.username,
                }
            }
            
            # Send to ourselves (Player 1)
            await self.send(text_data=json.dumps(match_data_for_p1))
            # Send to opponent (Player 2)
            await self.channel_layer.send(
                opponent_data['channel_name'],
                {
                    'type': 'send_match_found',
                    'data': match_data_for_p2
                }
            )
            print(f"[{self.user.username}] Match sent to both players.")
            return True # Match found
        return False # No match yet

    async def send_match_found(self, event):
        await self.send(text_data=json.dumps(event['data']))

    @database_sync_to_async
    def check_resources(self):
        return self.user.coins >= 20 and self.user.lives >= 1

    @database_sync_to_async
    def create_match_and_deduct(self, opponent):
        from apps.multiplayer.models import Match, MatchPlayer
        from apps.users.models import CustomUser
        from django.db import transaction
        
        try:
            with transaction.atomic():
                u1 = CustomUser.objects.select_for_update().get(id=self.user.id)
                u2 = CustomUser.objects.select_for_update().get(id=opponent.id)
                
                if u1.coins < 20 or u1.lives < 1 or u2.coins < 20 or u2.lives < 1:
                    return None
                    
                # Deduct resources
                u1.coins -= 20
                u1.lives -= 1
                u1.save(update_fields=['coins', 'lives'])
                
                u2.coins -= 20
                u2.lives -= 1
                u2.save(update_fields=['coins', 'lives'])
                
                # Create match
                match = Match.objects.create(
                    topic=self.topic,
                    status='active',
                    start_time=timezone.now()
                )
                
                MatchPlayer.objects.create(match=match, user=u1)
                MatchPlayer.objects.create(match=match, user=u2)
                
                print(f"Match created successfully: {match.id}")
                return match.id
        except Exception as e:
            print(f"Error in create_match_and_deduct: {e}")
            import traceback
            traceback.print_exc()
            return None

class GameRoomConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.match_id = self.scope['url_route']['kwargs']['match_id']
        self.room_group_name = f'match_{self.match_id}'
        self.user = self.scope["user"]

        if self.user.is_anonymous:
            await self.close()
            return

        # Check if user belongs to this match
        is_participant = await self.check_participant()
        if not is_participant:
            await self.close()
            return

        # Join room group
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        await self.accept()
        
        # Announce readiness
        await self.set_player_status('ready')
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'player_joined',
                'user_id': self.user.id,
                'username': self.user.username
            }
        )

    async def disconnect(self, close_code):
        # Handle disconnects (potential rage quit)
        if hasattr(self, 'match_id'):
            await self.handle_disconnect()
            
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name
            )

    async def receive(self, text_data):
        data = json.loads(text_data)
        action = data.get('action')

        if action == 'update_progress':
            score = data.get('score', 0)
            current_q = data.get('current_question', 0)
            total_q = data.get('total_questions', 0)
            
            await self.update_score(score)
            
            # Broadcast progress to opponent
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'opponent_progress',
                    'user_id': self.user.id,
                    'current_question': current_q,
                    'total_questions': total_q,
                    'score': score
                }
            )

        elif action == 'finish_test':
            score = data.get('score', 0)
            await self.finish_player_test(score)
            
            # Check if match is completely over
            match_finished = await self.check_match_finished()
            if match_finished:
                winner_id = await self.calculate_winner()
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'match_over',
                        'winner_id': winner_id
                    }
                )
            else:
                # Notify opponent that this player is waiting
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'player_waiting',
                        'user_id': self.user.id
                    }
                )
                
        elif action == 'malpractice_detected':
            # Instant forfeit
            await self.handle_malpractice()
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'opponent_forfeit',
                    'user_id': self.user.id,
                    'reason': 'Anti-cheat violation'
                }
            )

    async def update_score(self, score):
        player = await self.get_match_player()
        if player:
            await self.update_player_score(player, score)

    async def finish_player_test(self, score):
        player = await self.get_match_player()
        if player:
            await self.update_player_score(player, score)
            self._match_finished_flag = await self.mark_player_finished(player)

    async def check_match_finished(self):
        return getattr(self, '_match_finished_flag', False)

    # Handlers for group messages
    async def player_joined(self, event):
        await self.send(text_data=json.dumps(event))

    async def opponent_progress(self, event):
        if event['user_id'] != self.user.id:
            await self.send(text_data=json.dumps(event))

    async def player_waiting(self, event):
        if event['user_id'] != self.user.id:
            await self.send(text_data=json.dumps(event))

    async def match_over(self, event):
        await self.send(text_data=json.dumps(event))
        
    async def opponent_forfeit(self, event):
        if event['user_id'] != self.user.id:
            await self.send(text_data=json.dumps(event))

    # Database operations
    @database_sync_to_async
    def get_match_player(self):
        from apps.multiplayer.models import MatchPlayer
        return MatchPlayer.objects.filter(match_id=self.match_id, user=self.user).first()

    @database_sync_to_async
    def get_opponent_player(self):
        from apps.multiplayer.models import MatchPlayer
        return MatchPlayer.objects.filter(match_id=self.match_id).exclude(user=self.user).first()
        
    @database_sync_to_async
    def update_player_status(self, player, status):
        player.status = status
        player.save(update_fields=['status'])

    @database_sync_to_async
    def update_player_score(self, player, score):
        player.score = score
        player.save(update_fields=['score'])

    @database_sync_to_async
    def check_participant(self):
        from apps.multiplayer.models import MatchPlayer
        return MatchPlayer.objects.filter(match_id=self.match_id, user=self.user).exists()
        
    @database_sync_to_async
    def set_player_status(self, status):
        from apps.multiplayer.models import MatchPlayer
        MatchPlayer.objects.filter(match_id=self.match_id, user=self.user).update(status=status)

    @database_sync_to_async
    def handle_disconnect(self):
        from apps.multiplayer.models import Match, MatchPlayer
        from apps.users.models import CustomUser
        from django.utils import timezone

        match = Match.objects.get(id=self.match_id)
        if match.status == 'active':
            me = MatchPlayer.objects.get(match=match, user=self.user)
            if me.status != 'finished':
                me.status = 'disconnected'
                me.save(update_fields=['status'])
                
                # Auto-win for the other player
                other_player = MatchPlayer.objects.exclude(user=self.user).filter(match=match).first()
                if other_player:
                    match.status = 'completed'
                    match.end_time = timezone.now()
                    match.winner = other_player.user
                    match.save(update_fields=['status', 'end_time', 'winner'])
                    
                    other_player.is_winner = True
                    other_player.save(update_fields=['is_winner'])
                    
                    # Award 40 coins
                    u = CustomUser.objects.get(id=other_player.user.id)
                    u.coins += 40
                    u.save(update_fields=['coins'])

    @database_sync_to_async
    def mark_player_finished(self, player):
        from apps.multiplayer.models import Match
        from django.utils import timezone
        player.status = 'finished'
        player.finish_time = timezone.now()
        player.save(update_fields=['status', 'finish_time'])
        
        # Check if both finished
        m = Match.objects.get(id=self.match_id)
        if m.players.filter(status='finished').count() == 2:
            return True
        return False

    @database_sync_to_async
    def calculate_winner(self):
        from apps.users.models import CustomUser
        from apps.multiplayer.models import Match, MatchPlayer
        from django.utils import timezone

        match = Match.objects.get(id=self.match_id)
        
        # Don't recalculate if somehow already completed
        if match.status == 'completed':
            return match.winner.id if match.winner else None
            
        players = list(MatchPlayer.objects.filter(match=match))
        
        if len(players) != 2:
            return None
            
        p1, p2 = players
        
        winner = None
        
        # Option 1: Accuracy primary
        if p1.score > p2.score:
            winner = p1
            loser = p2
        elif p2.score > p1.score:
            winner = p2
            loser = p1
        else:
            # Tie breaker: Time 
            # Note: lower finish time = faster
            if p1.finish_time and p2.finish_time:
                if p1.finish_time < p2.finish_time:
                    winner = p1
                    loser = p2
                elif p2.finish_time < p1.finish_time:
                    winner = p2
                    loser = p1
                else:
                    # Absolute tie! Refund 20 to both
                    winner = None
            else:
                winner = None
                
        match.status = 'completed'
        match.end_time = timezone.now()
        
        if winner:
            match.winner = winner.user
            winner.is_winner = True
            winner.save()
            
            # Award 40 coins
            u = CustomUser.objects.get(id=winner.user.id)
            u.coins += 40
            u.save()
        else:
            # Refund 20 to both
            u1 = CustomUser.objects.get(id=p1.user.id)
            u2 = CustomUser.objects.get(id=p2.user.id)
            u1.coins += 20
            u2.coins += 20
            u1.save()
            u2.save()
            
        match.save()
        return match.winner.id if match.winner else -1 # -1 means Tie
