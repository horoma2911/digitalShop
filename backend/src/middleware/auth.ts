import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'replace_me_with_secure_value';

export interface AuthRequest extends Request {
  user?: any;
}

export default function authMiddleware(req: AuthRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers['authorization'];
  if (!authHeader) return res.status(401).send({ message: 'Missing Authorization header' });
  const parts = String(authHeader).split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') return res.status(401).send({ message: 'Invalid Authorization header' });

  const token = parts[1];
  try {
    const payload = jwt.verify(token, JWT_SECRET) as any;
    req.user = payload;
    next();
  } catch (err) {
    return res.status(401).send({ message: 'Invalid or expired token' });
  }
}
