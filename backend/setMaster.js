const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

async function main() {
  const hash = await bcrypt.hash('admin123%45', 10);
  await prisma.adminUser.upsert({
    where: { email: 'root@dinamixx.id' },
    update: {},
    create: { 
        email: 'root@dinamixx.id', 
        name: 'Root', 
        passwordHash: hash,
        role: 'Master',
        permissions: ['ALL_ACCESS']
    }
  });
  console.log('✅ Akun Master Berhasil Diupdate!');
}
main().finally(() => prisma.$disconnect());