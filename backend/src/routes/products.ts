import { Router } from 'express';
import { AppDataSource } from '../../ormconfig';
import { Product } from '../entities/Product';

const router = Router();
const repo = AppDataSource.getRepository(Product);

router.get('/', async (_, res) => {
  const items = await repo.find();
  res.send(items);
});

import authMiddleware from '../middleware/auth';

router.post('/', authMiddleware, async (req, res) => {
  const p = repo.create(req.body);
  await repo.save(p);
  res.status(201).send(p);
});

router.put('/:id', authMiddleware, async (req, res) => {
  const id = req.params.id;
  await repo.update(id, req.body);
  const updated = await repo.findOneBy({ id });
  res.send(updated);
});

router.delete('/:id', authMiddleware, async (req, res) => {
  const id = req.params.id;
  await repo.delete(id);
  res.send({ ok: true });
});

export default router;
