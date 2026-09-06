import { Router } from 'express';
import { AppDataSource } from '../../ormconfig';
import { User } from '../entities/User';
import { Shop } from '../entities/Shop';
import bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';

const router = Router();
const userRepo = AppDataSource.getRepository(User);
const shopRepo = AppDataSource.getRepository(Shop);

router.post('/register', async (req, res) => {
  try {
    const { email, password, shopName } = req.body;
    const exists = await userRepo.findOneBy({ email });
    if (exists) return res.status(400).send({ message: 'Email exists' });
    const hash = await bcrypt.hash(password, 10);
    const user = userRepo.create({ email, passwordHash: hash, role: 'client', shopId: 'global_shop' });
    await userRepo.save(user);

    // Ensure global shop
    let shop = await shopRepo.findOneBy({ id: 'global_shop' });
    if (!shop) {
      shop = shopRepo.create({ id: 'global_shop', ownerId: user.id, name: shopName || 'Global Shop' });
      await shopRepo.save(shop);
    }

    // Sign JWT
    const token = require('jsonwebtoken').sign({ id: user.id, role: user.role, shopId: user.shopId }, process.env.JWT_SECRET || 'replace_me_with_secure_value', { expiresIn: '30d' });
    return res.status(201).send({ user: { id: user.id, email: user.email, role: user.role, shopId: user.shopId }, shop, token });
  } catch (e) {
    console.error(e);
    return res.status(500).send({ message: 'Server error' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await userRepo.findOneBy({ email });
    if (!user) return res.status(404).send({ message: 'User not found' });
    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) return res.status(401).send({ message: 'Invalid credentials' });
    const shop = await shopRepo.findOneBy({ id: user.shopId || 'global_shop' });
    const token = require('jsonwebtoken').sign({ id: user.id, role: user.role, shopId: user.shopId }, process.env.JWT_SECRET || 'replace_me_with_secure_value', { expiresIn: '30d' });
    return res.send({ user: { id: user.id, email: user.email, role: user.role, shopId: user.shopId }, shop, token });
  } catch (e) {
    console.error(e);
    return res.status(500).send({ message: 'Server error' });
  }
});

export default router;
