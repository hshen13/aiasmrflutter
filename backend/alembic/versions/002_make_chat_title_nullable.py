"""make chat title nullable

Revision ID: 002
Revises: 001
Create Date: 2024-12-30 00:30:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '002'
down_revision = '001'
branch_labels = None
depends_on = None

def upgrade():
    # Make title column nullable in chats table
    op.alter_column('chats', 'title',
               existing_type=sa.String(length=100),
               nullable=True)

def downgrade():
    # Make title column non-nullable in chats table
    # First set any NULL values to empty string to avoid constraint violation
    op.execute("UPDATE chats SET title = '' WHERE title IS NULL")
    op.alter_column('chats', 'title',
               existing_type=sa.String(length=100),
               nullable=False)
