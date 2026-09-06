import { Router } from 'express';
import { AppDataSource } from '../../ormconfig';
import { User } from '../entities/User';

const router = Router();
const repo = AppDataSource.getRepository(User);

router.get('/', async (_, res) => {
  const items = await repo.find();
  // Return a safe shape
  const out = items.map(u => ({ id: u.id, email: u.email, role: u.role, shopId: u.shopId }));
  res.send(out);
});

export default router;
