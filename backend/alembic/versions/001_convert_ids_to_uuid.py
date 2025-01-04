"""Convert IDs to UUID

Revision ID: 001
Revises: 
Create Date: 2024-12-29 20:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID
import uuid

# revision identifiers, used by Alembic.
revision = '001'
down_revision = '000'
branch_labels = None
depends_on = None

def upgrade():
    # Add new UUID columns
    op.add_column('users', sa.Column('uuid_id', sa.String(36), nullable=True))
    op.add_column('characters', sa.Column('uuid_id', sa.String(36), nullable=True))
    op.add_column('chats', sa.Column('uuid_id', sa.String(36), nullable=True))
    op.add_column('messages', sa.Column('uuid_id', sa.String(36), nullable=True))
    op.add_column('tracks', sa.Column('uuid_id', sa.String(36), nullable=True))
    op.add_column('playlists', sa.Column('uuid_id', sa.String(36), nullable=True))
    op.add_column('recently_played', sa.Column('uuid_id', sa.String(36), nullable=True))

    # Add new foreign key columns
    op.add_column('characters', sa.Column('uuid_user_id', sa.String(36), nullable=True))
    op.add_column('chats', sa.Column('uuid_user_id', sa.String(36), nullable=True))
    op.add_column('chats', sa.Column('uuid_character_id', sa.String(36), nullable=True))
    op.add_column('messages', sa.Column('uuid_chat_id', sa.String(36), nullable=True))
    op.add_column('tracks', sa.Column('uuid_user_id', sa.String(36), nullable=True))
    op.add_column('playlists', sa.Column('uuid_user_id', sa.String(36), nullable=True))
    op.add_column('recently_played', sa.Column('uuid_user_id', sa.String(36), nullable=True))
    op.add_column('recently_played', sa.Column('uuid_track_id', sa.String(36), nullable=True))

    # Add new association table columns
    op.add_column('playlist_tracks', sa.Column('uuid_playlist_id', sa.String(36), nullable=True))
    op.add_column('playlist_tracks', sa.Column('uuid_track_id', sa.String(36), nullable=True))
    op.add_column('user_favorites', sa.Column('uuid_user_id', sa.String(36), nullable=True))
    op.add_column('user_favorites', sa.Column('uuid_track_id', sa.String(36), nullable=True))

    # Execute raw SQL to populate UUID columns
    conn = op.get_bind()

    # Update primary keys
    conn.execute("UPDATE users SET uuid_id = CAST(uuid_generate_v4() AS VARCHAR(36))")
    conn.execute("UPDATE characters SET uuid_id = CAST(uuid_generate_v4() AS VARCHAR(36))")
    conn.execute("UPDATE chats SET uuid_id = CAST(uuid_generate_v4() AS VARCHAR(36))")
    conn.execute("UPDATE messages SET uuid_id = CAST(uuid_generate_v4() AS VARCHAR(36))")
    conn.execute("UPDATE tracks SET uuid_id = CAST(uuid_generate_v4() AS VARCHAR(36))")
    conn.execute("UPDATE playlists SET uuid_id = CAST(uuid_generate_v4() AS VARCHAR(36))")
    conn.execute("UPDATE recently_played SET uuid_id = CAST(uuid_generate_v4() AS VARCHAR(36))")

    # Update foreign keys
    conn.execute("""
        UPDATE characters c
        SET uuid_user_id = u.uuid_id
        FROM users u
        WHERE c.user_id = u.id
    """)

    conn.execute("""
        UPDATE chats c
        SET uuid_user_id = u.uuid_id,
            uuid_character_id = ch.uuid_id
        FROM users u, characters ch
        WHERE c.user_id = u.id
        AND c.character_id = ch.id
    """)

    conn.execute("""
        UPDATE messages m
        SET uuid_chat_id = c.uuid_id
        FROM chats c
        WHERE m.chat_id = c.id
    """)

    conn.execute("""
        UPDATE tracks t
        SET uuid_user_id = u.uuid_id
        FROM users u
        WHERE t.user_id = u.id
    """)

    conn.execute("""
        UPDATE playlists p
        SET uuid_user_id = u.uuid_id
        FROM users u
        WHERE p.user_id = u.id
    """)

    conn.execute("""
        UPDATE recently_played rp
        SET uuid_user_id = u.uuid_id,
            uuid_track_id = t.uuid_id
        FROM users u, tracks t
        WHERE rp.user_id = u.id
        AND rp.track_id = t.id
    """)

    conn.execute("""
        UPDATE playlist_tracks pt
        SET uuid_playlist_id = p.uuid_id,
            uuid_track_id = t.uuid_id
        FROM playlists p, tracks t
        WHERE pt.playlist_id = p.id
        AND pt.track_id = t.id
    """)

    conn.execute("""
        UPDATE user_favorites uf
        SET uuid_user_id = u.uuid_id,
            uuid_track_id = t.uuid_id
        FROM users u, tracks t
        WHERE uf.user_id = u.id
        AND uf.track_id = t.id
    """)

    # Make UUID columns not nullable
    op.alter_column('users', 'uuid_id', nullable=False)
    op.alter_column('characters', 'uuid_id', nullable=False)
    op.alter_column('chats', 'uuid_id', nullable=False)
    op.alter_column('messages', 'uuid_id', nullable=False)
    op.alter_column('tracks', 'uuid_id', nullable=False)
    op.alter_column('playlists', 'uuid_id', nullable=False)
    op.alter_column('recently_played', 'uuid_id', nullable=False)

    op.alter_column('characters', 'uuid_user_id', nullable=False)
    op.alter_column('chats', 'uuid_user_id', nullable=False)
    op.alter_column('chats', 'uuid_character_id', nullable=False)
    op.alter_column('messages', 'uuid_chat_id', nullable=False)
    op.alter_column('tracks', 'uuid_user_id', nullable=False)
    op.alter_column('playlists', 'uuid_user_id', nullable=False)
    op.alter_column('recently_played', 'uuid_user_id', nullable=False)
    op.alter_column('recently_played', 'uuid_track_id', nullable=False)

    op.alter_column('playlist_tracks', 'uuid_playlist_id', nullable=False)
    op.alter_column('playlist_tracks', 'uuid_track_id', nullable=False)
    op.alter_column('user_favorites', 'uuid_user_id', nullable=False)
    op.alter_column('user_favorites', 'uuid_track_id', nullable=False)

    # Drop old foreign key constraints
    op.drop_constraint('characters_user_id_fkey', 'characters', type_='foreignkey')
    op.drop_constraint('chats_user_id_fkey', 'chats', type_='foreignkey')
    op.drop_constraint('chats_character_id_fkey', 'chats', type_='foreignkey')
    op.drop_constraint('messages_chat_id_fkey', 'messages', type_='foreignkey')
    op.drop_constraint('tracks_user_id_fkey', 'tracks', type_='foreignkey')
    op.drop_constraint('playlists_user_id_fkey', 'playlists', type_='foreignkey')
    op.drop_constraint('recently_played_user_id_fkey', 'recently_played', type_='foreignkey')
    op.drop_constraint('recently_played_track_id_fkey', 'recently_played', type_='foreignkey')
    op.drop_constraint('playlist_tracks_playlist_id_fkey', 'playlist_tracks', type_='foreignkey')
    op.drop_constraint('playlist_tracks_track_id_fkey', 'playlist_tracks', type_='foreignkey')
    op.drop_constraint('user_favorites_user_id_fkey', 'user_favorites', type_='foreignkey')
    op.drop_constraint('user_favorites_track_id_fkey', 'user_favorites', type_='foreignkey')

    # Drop old primary key constraints
    op.drop_constraint('users_pkey', 'users', type_='primary')
    op.drop_constraint('characters_pkey', 'characters', type_='primary')
    op.drop_constraint('chats_pkey', 'chats', type_='primary')
    op.drop_constraint('messages_pkey', 'messages', type_='primary')
    op.drop_constraint('tracks_pkey', 'tracks', type_='primary')
    op.drop_constraint('playlists_pkey', 'playlists', type_='primary')
    op.drop_constraint('recently_played_pkey', 'recently_played', type_='primary')

    # Drop old columns
    op.drop_column('users', 'id')
    op.drop_column('characters', 'id')
    op.drop_column('characters', 'user_id')
    op.drop_column('chats', 'id')
    op.drop_column('chats', 'user_id')
    op.drop_column('chats', 'character_id')
    op.drop_column('messages', 'id')
    op.drop_column('messages', 'chat_id')
    op.drop_column('tracks', 'id')
    op.drop_column('tracks', 'user_id')
    op.drop_column('playlists', 'id')
    op.drop_column('playlists', 'user_id')
    op.drop_column('recently_played', 'id')
    op.drop_column('recently_played', 'user_id')
    op.drop_column('recently_played', 'track_id')
    op.drop_column('playlist_tracks', 'playlist_id')
    op.drop_column('playlist_tracks', 'track_id')
    op.drop_column('user_favorites', 'user_id')
    op.drop_column('user_favorites', 'track_id')

    # Rename UUID columns
    op.alter_column('users', 'uuid_id', new_column_name='id')
    op.alter_column('characters', 'uuid_id', new_column_name='id')
    op.alter_column('characters', 'uuid_user_id', new_column_name='user_id')
    op.alter_column('chats', 'uuid_id', new_column_name='id')
    op.alter_column('chats', 'uuid_user_id', new_column_name='user_id')
    op.alter_column('chats', 'uuid_character_id', new_column_name='character_id')
    op.alter_column('messages', 'uuid_id', new_column_name='id')
    op.alter_column('messages', 'uuid_chat_id', new_column_name='chat_id')
    op.alter_column('tracks', 'uuid_id', new_column_name='id')
    op.alter_column('tracks', 'uuid_user_id', new_column_name='user_id')
    op.alter_column('playlists', 'uuid_id', new_column_name='id')
    op.alter_column('playlists', 'uuid_user_id', new_column_name='user_id')
    op.alter_column('recently_played', 'uuid_id', new_column_name='id')
    op.alter_column('recently_played', 'uuid_user_id', new_column_name='user_id')
    op.alter_column('recently_played', 'uuid_track_id', new_column_name='track_id')
    op.alter_column('playlist_tracks', 'uuid_playlist_id', new_column_name='playlist_id')
    op.alter_column('playlist_tracks', 'uuid_track_id', new_column_name='track_id')
    op.alter_column('user_favorites', 'uuid_user_id', new_column_name='user_id')
    op.alter_column('user_favorites', 'uuid_track_id', new_column_name='track_id')

    # Add new primary key constraints
    op.create_primary_key('users_pkey', 'users', ['id'])
    op.create_primary_key('characters_pkey', 'characters', ['id'])
    op.create_primary_key('chats_pkey', 'chats', ['id'])
    op.create_primary_key('messages_pkey', 'messages', ['id'])
    op.create_primary_key('tracks_pkey', 'tracks', ['id'])
    op.create_primary_key('playlists_pkey', 'playlists', ['id'])
    op.create_primary_key('recently_played_pkey', 'recently_played', ['id'])

    # Add new foreign key constraints
    op.create_foreign_key('characters_user_id_fkey', 'characters', 'users', ['user_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('chats_user_id_fkey', 'chats', 'users', ['user_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('chats_character_id_fkey', 'chats', 'characters', ['character_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('messages_chat_id_fkey', 'messages', 'chats', ['chat_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('tracks_user_id_fkey', 'tracks', 'users', ['user_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('playlists_user_id_fkey', 'playlists', 'users', ['user_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('recently_played_user_id_fkey', 'recently_played', 'users', ['user_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('recently_played_track_id_fkey', 'recently_played', 'tracks', ['track_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('playlist_tracks_playlist_id_fkey', 'playlist_tracks', 'playlists', ['playlist_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('playlist_tracks_track_id_fkey', 'playlist_tracks', 'tracks', ['track_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('user_favorites_user_id_fkey', 'user_favorites', 'users', ['user_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('user_favorites_track_id_fkey', 'user_favorites', 'tracks', ['track_id'], ['id'], ondelete='CASCADE')

def downgrade():
    # This is a one-way migration - no downgrade supported
    pass
