import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('messages')
export class Message {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @Column('text')
  text: string;

  @Column()
  isSentByMe: boolean;

  @CreateDateColumn()
  timestamp: Date;
}