#!/bin/bash

echo "=== pgvector Verification ==="
echo ""

echo "1. Checking PostgreSQL 16 is running..."
if brew services list | grep -q "postgresql@16.*started"; then
  echo "   ✓ PostgreSQL 16 is running"
else
  echo "   ✗ PostgreSQL 16 is NOT running"
  exit 1
fi

echo ""
echo "2. Checking pgvector library..."
if [ -f "/opt/homebrew/opt/postgresql@16/lib/postgresql/vector.dylib" ]; then
  echo "   ✓ vector.dylib found"
else
  echo "   ✗ vector.dylib NOT found"
  exit 1
fi

echo ""
echo "3. Checking pgvector SQL files..."
if [ -f "/opt/homebrew/opt/postgresql@16/share/postgresql@16/extension/vector.control" ]; then
  echo "   ✓ SQL extension files found"
else
  echo "   ✗ SQL extension files NOT found"
  exit 1
fi

echo ""
echo "4. Testing pgvector extension..."
/opt/homebrew/opt/postgresql@16/bin/psql -h localhost -p 5432 -d ai_rules_context -c "SELECT extversion FROM pg_extension WHERE extname = 'vector';" 2>/dev/null
if [ $? -eq 0 ]; then
  echo "   ✓ pgvector extension is loaded"
else
  echo "   ✗ pgvector extension is NOT loaded"
  exit 1
fi

echo ""
echo "5. Testing vector operations..."
/opt/homebrew/opt/postgresql@16/bin/psql -h localhost -p 5432 -d ai_rules_context -c "SELECT '[1,2,3]'::vector;" 2>/dev/null
if [ $? -eq 0 ]; then
  echo "   ✓ Vector operations working"
else
  echo "   ✗ Vector operations NOT working"
  exit 1
fi

echo ""
echo "=== ALL CHECKS PASSED ==="
echo "pgvector is ready for Arcana installation!"
