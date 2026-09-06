import { DataSource } from 'typeorm';
import 'reflect-metadata';
import { User } from './src/entities/User';
import { Shop } from './src/entities/Shop';
import { Product } from './src/entities/Product';
import { Sale } from './src/entities/Sale';
import { Expense } from './src/entities/Expense';

const useSqlite = process.env.USE_SQLITE === 'true';

export const AppDataSource = new DataSource(
  useSqlite
    ? {
        type: 'sqlite',
        database: process.env.SQLITE_FILE || 'dev.sqlite',
        synchronize: true,
        logging: false,
        entities: [User, Shop, Product, Sale, Expense],
      }
    : {
        type: 'postgres',
        host: process.env.DB_HOST || 'localhost',
        port: Number(process.env.DB_PORT || 5432),
        username: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASS || 'postgres',
        database: process.env.DB_NAME || 'gouanzouh',
        synchronize: process.env.NODE_ENV !== 'production',
        logging: process.env.NODE_ENV === 'development',
        entities: [User, Shop, Product, Sale, Expense],
        migrations: ['dist/migrations/**/*.js'],
        migrationsRun: true,
      }
);
