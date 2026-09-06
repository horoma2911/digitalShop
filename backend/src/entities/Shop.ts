import { Entity, PrimaryColumn, Column } from 'typeorm';

@Entity()
export class Shop {
  @PrimaryColumn()
  id!: string;

  @Column()
  ownerId!: string;

  @Column()
  name!: string;
}
