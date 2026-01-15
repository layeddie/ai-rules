defmodule ArcanaSetup.RepoMigration do
  use Ecto.Migration

  def up do
    # Create Arcana tables
    execute """
    CREATE EXTENSION IF NOT EXISTS vector;

    CREATE TABLE IF NOT EXISTS arcana_documents (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      collection TEXT NOT NULL,
      embedding vector(1536),
      chunk_index INTEGER NOT NULL,
      chunk_text TEXT NOT NULL,
      metadata JSONB,
      inserted_at TIMESTAMPTZ NOT NULL,
      updated_at TIMESTAMPTZ NOT NULL
    );

    CREATE INDEX IF NOT EXISTS arcana_documents_embedding_idx ON arcana_documents USING ivfflat (vector cosine_ops);
    """
  end

  def down do
    # Drop Arcana tables
    execute """
    DROP TABLE IF EXISTS arcana_documents;
    """
  end
end
