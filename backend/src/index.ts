import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { AppDataSource } from '../ormconfig';
import authRoutes from './routes/auth';
import productsRoutes from './routes/products';
import salesRoutes from './routes/sales';
import expensesRoutes from './routes/expenses';
import usersRoutes from './routes/users';
import shopsRoutes from './routes/shops';

dotenv.config();

AppDataSource.initialize().then(() => {
  const app = express();
  app.use(cors());
  app.use(express.json());

  app.use('/auth', authRoutes);
  app.use('/products', productsRoutes);
  app.use('/sales', salesRoutes);
  app.use('/expenses', expensesRoutes);
  app.use('/users', usersRoutes);
  app.use('/shops', shopsRoutes);

  app.get('/health', (_, res) => res.send({ ok: true }));

  const port = process.env.PORT || 3000;
  app.listen(port, () => console.log(`API listening on ${port}`));
}).catch(err => {
  console.error('DB init error', err);
});
