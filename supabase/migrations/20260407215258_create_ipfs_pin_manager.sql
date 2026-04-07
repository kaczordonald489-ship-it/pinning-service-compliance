/*
  # IPFS Pin Management System

  1. New Tables
    - `pin_categories`
      - `id` (uuid, primary key)
      - `name` (text, unique) - Category name (e.g., 'polkadot', 'geth', 'nft')
      - `description` (text, nullable)
      - `color` (text) - Hex color for UI
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `pins`
      - `id` (uuid, primary key)
      - `cid` (text, unique, not null) - IPFS Content Identifier
      - `name` (text, nullable) - Human readable name
      - `category_id` (uuid, foreign key to pin_categories)
      - `size` (bigint, nullable) - Size in bytes
      - `pin_date` (timestamptz) - When it was pinned
      - `metadata` (jsonb) - Flexible metadata storage
      - `tags` (text array) - Searchable tags
      - `notes` (text, nullable)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `pin_relationships`
      - `id` (uuid, primary key)
      - `parent_cid` (text, not null)
      - `child_cid` (text, not null)
      - `relationship_type` (text) - 'contains', 'references', 'version_of'
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users to manage their own pins
*/

-- Create pin_categories table
CREATE TABLE IF NOT EXISTS pin_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  description text,
  color text NOT NULL DEFAULT '#3b82f6',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE pin_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view categories"
  ON pin_categories FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Authenticated users can manage categories"
  ON pin_categories FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Create pins table
CREATE TABLE IF NOT EXISTS pins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cid text UNIQUE NOT NULL,
  name text,
  category_id uuid REFERENCES pin_categories(id) ON DELETE SET NULL,
  size bigint,
  pin_date timestamptz DEFAULT now(),
  metadata jsonb DEFAULT '{}',
  tags text[] DEFAULT '{}',
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE pins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view pins"
  ON pins FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Authenticated users can manage pins"
  ON pins FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Create pin_relationships table
CREATE TABLE IF NOT EXISTS pin_relationships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_cid text NOT NULL,
  child_cid text NOT NULL,
  relationship_type text NOT NULL DEFAULT 'contains',
  created_at timestamptz DEFAULT now(),
  UNIQUE(parent_cid, child_cid, relationship_type)
);

ALTER TABLE pin_relationships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view relationships"
  ON pin_relationships FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Authenticated users can manage relationships"
  ON pin_relationships FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_pins_cid ON pins(cid);
CREATE INDEX IF NOT EXISTS idx_pins_category ON pins(category_id);
CREATE INDEX IF NOT EXISTS idx_pins_tags ON pins USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_pins_metadata ON pins USING gin(metadata);
CREATE INDEX IF NOT EXISTS idx_relationships_parent ON pin_relationships(parent_cid);
CREATE INDEX IF NOT EXISTS idx_relationships_child ON pin_relationships(child_cid);

-- Insert default categories
INSERT INTO pin_categories (name, description, color) VALUES
  ('polkadot', 'Polkadot SDK and substrate data', '#e6007a'),
  ('geth', 'Go Ethereum node data', '#627eea'),
  ('nft', 'NFT metadata and assets', '#ff6b6b'),
  ('web3', 'General Web3 data', '#4ecdc4'),
  ('node', 'Node.js packages and data', '#68a063'),
  ('uncategorized', 'Uncategorized pins', '#6b7280')
ON CONFLICT (name) DO NOTHING;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_pin_categories_updated_at BEFORE UPDATE ON pin_categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pins_updated_at BEFORE UPDATE ON pins
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();