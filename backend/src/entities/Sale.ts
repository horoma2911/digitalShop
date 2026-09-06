import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity()
export class Sale {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  shopId!: string;

  @Column()
  productId!: string;

  @Column()
  productName!: string;

  @Column('int')
  quantity!: number;

  @Column('double precision')
  totalPrice!: number;

  @Column('double precision')
  profit!: number;

  @Column({ type: 'datetime', default: () => "CURRENT_TIMESTAMP" })
  date!: Date;
}
