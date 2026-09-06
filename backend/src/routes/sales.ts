import { Router } from 'express';
import { AppDataSource } from '../../ormconfig';
import { Sale } from '../entities/Sale';
import { Product } from '../entities/Product';

const router = Router();
const saleRepo = AppDataSource.getRepository(Sale);
const productRepo = AppDataSource.getRepository(Product);

router.get('/', async (_, res) => {
  const items = await saleRepo.find();
  res.send(items);
});

import authMiddleware from '../middleware/auth';

router.post('/', authMiddleware, async (req, res) => {
  const { productId, quantity } = req.body;
  await AppDataSource.manager.transaction(async (manager) => {
    const product = await manager.findOne(Product, { where: { id: productId } });
    if (!product) throw new Error('Product not found');
    if (product.stock < quantity) throw new Error('Insufficient stock');
    product.stock = product.stock - quantity;
    await manager.save(product);

    const sale = manager.create(Sale, {
      shopId: product.shopId,
      productId: product.id,
      productName: product.name,
      quantity,
      totalPrice: product.salePrice * quantity,
      profit: (product.salePrice - product.costPrice) * quantity,
    });
    await manager.save(sale);
    res.status(201).send(sale);
  }).catch(err => {
    console.error(err);
    res.status(400).send({ message: err.message || 'Failed' });
  });
});

router.put('/:id', authMiddleware, async (req, res) => {
  const id = req.params.id;
  const { quantity } = req.body;
  await AppDataSource.manager.transaction(async (manager) => {
    const sale = await manager.findOne(Sale, { where: { id } });
    if (!sale) throw new Error('Sale not found');
    const product = await manager.findOne(Product, { where: { id: sale.productId } });
    if (!product) throw new Error('Product not found');

    const stockDiff = sale.quantity - quantity;
    if (product.stock + stockDiff < 0) throw new Error('Insufficient stock for adjustment');

    product.stock = product.stock + stockDiff;
    sale.quantity = quantity;
    sale.totalPrice = product.salePrice * quantity;
    sale.profit = (product.salePrice - product.costPrice) * quantity;

    await manager.save(product);
    await manager.save(sale);

    res.send(sale);
  }).catch(err => {
    console.error(err);
    res.status(400).send({ message: err.message || 'Failed' });
  });
});

router.delete('/:id', authMiddleware, async (req, res) => {
  const id = req.params.id;
  await AppDataSource.manager.transaction(async (manager) => {
    const sale = await manager.findOne(Sale, { where: { id } });
    if (!sale) throw new Error('Sale not found');
    const product = await manager.findOne(Product, { where: { id: sale.productId } });
    if (product) product.stock = product.stock + sale.quantity;
    await manager.save(product!);
    await manager.delete(Sale, id);
    res.send({ ok: true });
  }).catch(err => {
    console.error(err);
    res.status(400).send({ message: err.message || 'Failed' });
  });
});

export default router;
