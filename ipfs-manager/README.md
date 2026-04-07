# IPFS Pin Manager

Organize and manage your IPFS daemon pins with categories, tags, and metadata.

## Features

- Import existing pins from your IPFS daemon
- Auto-categorize pins (Polkadot, Geth, NFT, Web3, Node)
- Web interface to browse and search pins
- Track relationships between pins
- Add custom tags and notes
- View statistics by category

## Setup

1. Make sure your environment variables are set:
```bash
export VITE_SUPABASE_URL="your-supabase-url"
export VITE_SUPABASE_ANON_KEY="your-supabase-key"
```

2. Make sure your IPFS daemon is running:
```bash
ipfs daemon
```

3. Install dependencies:
```bash
npm install @supabase/supabase-js kubo-rpc-client
```

## Import Your Pins

Run the import script to fetch all pins from your IPFS daemon:

```bash
npx tsx ipfs-manager/import-pins.ts
```

This will:
- Connect to your local IPFS daemon (localhost:5001)
- Fetch all recursive pins
- Auto-detect categories based on CID and metadata
- Import them into the database
- Skip any pins that already exist

## View Your Pins

Open the web interface in your browser:

```bash
# Replace with your actual Supabase credentials
sed -i 's/__SUPABASE_URL__/your-url/g' ipfs-manager/index.html
sed -i 's/__SUPABASE_KEY__/your-key/g' ipfs-manager/index.html

# Open in browser
open ipfs-manager/index.html
```

## Categories

The system auto-detects these categories:

- **Polkadot** - Substrate, DOT, Polkadot SDK
- **Geth** - Ethereum, ETH, Go Ethereum
- **NFT** - NFT metadata, tokens, ERC721
- **Web3** - General Web3 data
- **Node** - Node.js packages and data
- **Uncategorized** - Everything else

## Manual Categorization

You can update pins manually through the Supabase dashboard or add a CLI command:

```sql
-- Update a pin's category
UPDATE pins
SET category_id = (SELECT id FROM pin_categories WHERE name = 'polkadot')
WHERE cid = 'your-cid-here';

-- Add tags
UPDATE pins
SET tags = array_append(tags, 'substrate')
WHERE cid = 'your-cid-here';

-- Add notes
UPDATE pins
SET notes = 'This contains important blockchain state data'
WHERE cid = 'your-cid-here';
```

## Advanced Features

### Track Relationships

Link related pins together:

```sql
INSERT INTO pin_relationships (parent_cid, child_cid, relationship_type)
VALUES ('parent-cid', 'child-cid', 'contains');
```

### Custom Metadata

Store any JSON metadata:

```sql
UPDATE pins
SET metadata = jsonb_set(metadata, '{network}', '"mainnet"')
WHERE cid = 'your-cid-here';
```

## Troubleshooting

**IPFS daemon not responding:**
- Make sure IPFS daemon is running: `ipfs daemon`
- Check it's on the default port: `ipfs config Addresses.API`

**Import script fails:**
- Check your Supabase credentials
- Make sure the migration was applied
- Check IPFS daemon logs

**Pins not showing:**
- Refresh the web interface
- Check browser console for errors
- Verify pins exist in database: `SELECT COUNT(*) FROM pins;`
