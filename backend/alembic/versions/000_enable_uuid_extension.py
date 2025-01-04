"""Enable UUID extension

Revision ID: 000
Revises: 
Create Date: 2024-12-29 19:55:00.000000

"""
from alembic import op

# revision identifiers, used by Alembic.
revision = '000'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    op.execute('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"')

def downgrade():
    op.execute('DROP EXTENSION IF EXISTS "uuid-ossp"')
