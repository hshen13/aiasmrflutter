"""add gif_url to tracks

Revision ID: 003
Revises: c70f50338151
Create Date: 2024-01-10 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '003'
down_revision = 'c70f50338151'
branch_labels = None
depends_on = None


def upgrade():
    # Add gif_url column to tracks table
    op.add_column('tracks', sa.Column('gif_url', sa.String(255)))
    
    # Set default gif_url for existing tracks
    op.execute("UPDATE tracks SET gif_url = '/static/gif/kafka_night.gif'")


def downgrade():
    # Remove gif_url column from tracks table
    op.drop_column('tracks', 'gif_url')
