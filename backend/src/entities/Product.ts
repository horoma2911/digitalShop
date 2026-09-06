import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity()
export class Product {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  shopId!: string;

  @Column()
  name!: string;

  @Column()
  category!: string;

  @Column({ nullable: true })
  barcode?: string;

  @Column('double precision')
  costPrice!: number;

  @Column('double precision')
  salePrice!: number;

  @Column('int')
  stock!: number;
}
