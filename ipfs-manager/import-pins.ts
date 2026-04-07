#!/usr/bin/env node
import { createClient } from '@supabase/supabase-js'
import { create } from 'kubo-rpc-client'

// Supabase setup
const supabaseUrl = process.env.VITE_SUPABASE_URL!
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY!
const supabase = createClient(supabaseUrl, supabaseKey)

// IPFS client setup
const ipfsClient = create({
  host: 'localhost',
  port: 5001,
  protocol: 'http'
})

interface PinData {
  cid: string
  name?: string
  categoryId?: string
  tags: string[]
  size?: number
}

async function getCategoryId(categoryName: string): Promise<string | null> {
  const { data, error } = await supabase
    .from('pin_categories')
    .select('id')
    .eq('name', categoryName.toLowerCase())
    .maybeSingle()

  if (error) {
    console.error('Error fetching category:', error)
    return null
  }

  return data?.id || null
}

async function detectCategory(cid: string, name?: string): Promise<string> {
  const searchText = `${cid} ${name || ''}`.toLowerCase()

  if (searchText.includes('polkadot') || searchText.includes('substrate') || searchText.includes('dot')) {
    return 'polkadot'
  } else if (searchText.includes('geth') || searchText.includes('ethereum') || searchText.includes('eth')) {
    return 'geth'
  } else if (searchText.includes('nft') || searchText.includes('token') || searchText.includes('erc721')) {
    return 'nft'
  } else if (searchText.includes('web3')) {
    return 'web3'
  } else if (searchText.includes('node') || searchText.includes('npm')) {
    return 'node'
  }

  return 'uncategorized'
}

async function importPins() {
  console.log('Fetching pins from IPFS daemon...')

  try {
    const pins = ipfsClient.pin.ls({ type: 'recursive' })
    let count = 0
    let imported = 0
    let skipped = 0

    for await (const pin of pins) {
      count++
      const cid = pin.cid.toString()

      console.log(`Processing pin ${count}: ${cid}`)

      // Check if pin already exists
      const { data: existing } = await supabase
        .from('pins')
        .select('id')
        .eq('cid', cid)
        .maybeSingle()

      if (existing) {
        console.log(`  ⚠️  Already exists, skipping`)
        skipped++
        continue
      }

      // Detect category
      const categoryName = await detectCategory(cid)
      const categoryId = await getCategoryId(categoryName)

      // Try to get size
      let size: number | undefined
      try {
        const stats = await ipfsClient.files.stat(`/ipfs/${cid}`, { timeout: 5000 })
        size = stats.cumulativeSize
      } catch (err) {
        console.log(`  ℹ️  Could not get size`)
      }

      // Insert pin
      const { error } = await supabase
        .from('pins')
        .insert({
          cid,
          category_id: categoryId,
          size,
          tags: [categoryName],
          metadata: { imported: true, import_date: new Date().toISOString() }
        })

      if (error) {
        console.error(`  ❌ Error inserting pin:`, error.message)
      } else {
        console.log(`  ✓ Imported as ${categoryName}`)
        imported++
      }
    }

    console.log(`\n📊 Summary:`)
    console.log(`   Total pins found: ${count}`)
    console.log(`   Imported: ${imported}`)
    console.log(`   Skipped (already exist): ${skipped}`)

  } catch (error) {
    console.error('Error importing pins:', error)
    process.exit(1)
  }
}

// Run import
importPins().catch(console.error)
