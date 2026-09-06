import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity()
export class Expense {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  shopId!: string;

  @Column()
  category!: string;

  @Column()
  description!: string;

  @Column('double precision')
  amount!: number;

  @Column({ type: 'datetime' })
  date!: Date;
}
