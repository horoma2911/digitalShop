#!/bin/bash

# TypeORM Migration Guide for Gouanzouh API
# This file contains commands and setup for database migrations

echo "═══════════════════════════════════════════════════════════════"
echo "TypeORM Migration Setup & Commands"
echo "═══════════════════════════════════════════════════════════════"

# 1. GENERATE MIGRATIONS FROM ENTITIES (one-time setup)
echo ""
echo "1️⃣  Generate initial migration from entities:"
echo "   npm run typeorm migration:generate -- -n InitialSchema"
echo "   (Run once after defining all entities)"

# 2. CREATE EMPTY MIGRATION (for manual SQL changes)
echo ""
echo "2️⃣  Create an empty migration:"
echo "   npm run typeorm migration:create -- -n AddNewColumn"
echo "   (Edit src/migrations/[timestamp]-AddNewColumn.ts to add logic)"

# 3. RUN MIGRATIONS (production deployment)
echo ""
echo "3️⃣  Run pending migrations:"
echo "   npm run typeorm migration:run"
echo "   (Executes all .up() migrations not yet applied)"

# 4. REVERT LAST MIGRATION (rollback)
echo ""
echo "4️⃣  Revert last migration:"
echo "   npm run typeorm migration:revert"
echo "   (Executes .down() of most recent migration)"

# 5. SHOW MIGRATION STATUS
echo ""
echo "5️⃣  Show migration status:"
echo "   npm run typeorm migration:show"
echo "   (Lists all migrations and whether they've run)"

# PRODUCTION DEPLOYMENT WORKFLOW:
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "📋 PRODUCTION DEPLOYMENT WORKFLOW:"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "1. Commit migration files to git"
echo "2. Update ormconfig.ts (set synchronize: false for production)"
echo "3. SSH into Contabo VPS"
echo "4. Pull latest code: git pull origin main"
echo "5. Start services: docker-compose -f docker-compose.prod.yml up -d"
echo "6. Run migrations in API container:"
echo "   docker-compose -f docker-compose.prod.yml exec api npm run typeorm migration:run"
echo "7. Verify migrations ran: docker-compose logs api | grep -i migration"
echo ""

# DOCKER-BASED MIGRATION COMMANDS:
echo "═══════════════════════════════════════════════════════════════"
echo "🐳 DOCKER MIGRATION COMMANDS:"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Run migrations in container:"
echo "  docker-compose -f docker-compose.prod.yml exec api npm run typeorm migration:run"
echo ""
echo "Show migration status in container:"
echo "  docker-compose -f docker-compose.prod.yml exec api npm run typeorm migration:show"
echo ""
echo "Revert last migration in container:"
echo "  docker-compose -f docker-compose.prod.yml exec api npm run typeorm migration:revert"
echo ""

# ORMCONFIG PRODUCTION SETTINGS:
echo "═══════════════════════════════════════════════════════════════"
echo "⚙️  UPDATE ormconfig.ts for Production:"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Replace synchronize: true with:"
echo "  synchronize: false  // Disable auto-schema creation"
echo ""
echo "Add these properties:"
echo "  migrations: ['dist/migrations/**/*.js']"
echo "  migrationsRun: true  // Auto-run migrations on startup (optional)"
echo "  migrationsTableName: 'typeorm_migrations'"
echo ""

# TROUBLESHOOTING:
echo "═══════════════════════════════════════════════════════════════"
echo "🔧 TROUBLESHOOTING:"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "❌ Migration fails with 'relation already exists':"
echo "   → Migrations already ran. Check: npm run typeorm migration:show"
echo ""
echo "❌ Cannot connect to database:"
echo "   → Check container is running: docker-compose ps"
echo "   → Verify DB_* env vars in .env file"
echo ""
echo "❌ Need to rollback all migrations:"
echo "   → Run revert multiple times or manually drop/recreate database"
echo "   → docker-compose exec db dropdb -U $DB_USER $DB_NAME"
echo "   → docker-compose exec db createdb -U $DB_USER $DB_NAME"
echo ""

echo "✅ Setup complete! See npm scripts in package.json for typeorm commands"
