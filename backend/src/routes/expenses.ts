import { Router } from 'express';
import { AppDataSource } from '../../ormconfig';
import { Expense } from '../entities/Expense';

const router = Router();
const repo = AppDataSource.getRepository(Expense);

router.get('/', async (_, res) => {
  const items = await repo.find();
  res.send(items);
});

import authMiddleware from '../middleware/auth';

router.post('/', authMiddleware, async (req, res) => {
  const e = repo.create(req.body);
  await repo.save(e);
  res.status(201).send(e);
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
