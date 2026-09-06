import { Router } from 'express';
import { AppDataSource } from '../../ormconfig';
import { Shop } from '../entities/Shop';

const router = Router();
const repo = AppDataSource.getRepository(Shop);

router.get('/', async (_, res) => {
  const items = await repo.find();
  res.send(items);
});

export default router;
