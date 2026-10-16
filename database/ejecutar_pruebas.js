const fs = require('fs');
const path = require('path');

require(path.join(__dirname, '..', 'backend', 'node_modules', 'dotenv')).config({
  path: path.join(__dirname, '..', '.env'),
});
const { Client } = require(path.join(__dirname, '..', 'backend', 'node_modules', 'pg'));
const bcrypt = require(path.join(__dirname, '..', 'backend', 'node_modules', 'bcryptjs'));

const lineas = [];
const anotar = (texto) => {
  lineas.push(texto);
  console.log(texto);
};

function cliente(connectionString) {
  return new Client({ connectionString, ssl: { rejectUnauthorized: false } });
}

async function esperarError(accion) {
  try {
    await accion();
    return null;
  } catch (error) {
    return error.message;
  }
}

(async () => {
  const dueno = cliente(process.env.DATABASE_URL);
  await dueno.connect();
  const meta = await dueno.query('SELECT version() AS ver, current_database() AS db, current_user AS u, current_date AS hoy');
  anotar('SERVIDOR ' + String(meta.rows[0].ver).split(',')[0]);
  anotar('BASE ' + meta.rows[0].db);
  anotar('USUARIO ' + meta.rows[0].u);
  anotar('FECHA ' + meta.rows[0].hoy.toISOString().slice(0, 10));
  anotar('NOTA No hay PostgreSQL 17 local. La ejecución usa el servidor conectado de la aplicación.');

  const sql = fs.readFileSync(path.join(__dirname, 'sert_biblioteca.sql'), 'utf8');
  await dueno.query(sql);
  anotar('SCRIPT OK');

  const conteos = await dueno.query(`
    SELECT
      (SELECT count(*)::int FROM sert_libro) AS titulos,
      (SELECT count(*)::int FROM sert_ejemplar WHERE estado = 'DISPONIBLE') AS disponibles,
      (SELECT count(*)::int FROM sert_ejemplar) AS ejemplares,
      (SELECT count(*)::int FROM sert_socio WHERE estado = 'ACTIVO') AS socios,
      (SELECT count(*)::int FROM sert_prestamo WHERE estado = 'ABIERTO') AS abiertos,
      (SELECT count(DISTINCT id_prestamo)::int FROM sert_v_prestamos_vencidos) AS vencidos,
      (SELECT COALESCE(sum(monto), 0) FROM sert_multa WHERE estado = 'PENDIENTE') AS multa
  `);
  anotar('TABLA25 ' + JSON.stringify(conteos.rows[0]));

  const usuarios = await dueno.query(`
    SELECT u.usuario, r.nombre AS rol, u.id_socio IS NOT NULL AS tiene_socio
      FROM sert_usuario u JOIN sert_rol r ON r.id_rol = u.id_rol
     ORDER BY u.id_usuario
  `);
  for (const fila of usuarios.rows) {
    anotar(`USUARIO ${fila.usuario} rol=${fila.rol} socio=${fila.tiene_socio}`);
  }
  const hashes = await dueno.query('SELECT usuario, clave_hash FROM sert_usuario ORDER BY id_usuario');
  const claves = { admin: 'admin123', biblio: 'biblio123', lector: 'lector123' };
  for (const fila of hashes.rows) {
    const ok = await bcrypt.compare(claves[fila.usuario], fila.clave_hash);
    anotar(`BCRYPT ${fila.usuario} ${ok ? 'VALIDO' : 'INVALIDO'}`);
  }

  const fk = await dueno.query(`
    SELECT conname, pg_get_constraintdef(oid) AS def
      FROM pg_constraint
     WHERE conrelid = 'sert_detalle_prestamo'::regclass AND contype = 'f'
  `);
  anotar('FK_DETALLE ' + fk.rows.map((f) => f.def).join(' | '));

  async function rechazo(codigo, sqlPrueba) {
    await dueno.query('BEGIN');
    const mensaje = await esperarError(() => dueno.query(sqlPrueba));
    await dueno.query('ROLLBACK');
    anotar(`${codigo} ${mensaje ? 'RECHAZADO: ' + mensaje.split('\n')[0] : 'NO RECHAZADO'}`);
  }

  await rechazo('PF-08', `
    INSERT INTO sert_prestamo (id_socio, id_usuario, fecha_vencimiento)
    VALUES (2, 2, CURRENT_DATE + 14);
    INSERT INTO sert_detalle_prestamo (id_prestamo, id_ejemplar)
    VALUES (currval(pg_get_serial_sequence('sert_prestamo','id_prestamo')),
            (SELECT id_ejemplar FROM sert_ejemplar WHERE estado = 'DISPONIBLE' LIMIT 1));
  `);

  await rechazo('PF-18', `
    INSERT INTO sert_prestamo (id_socio, id_usuario, fecha_vencimiento)
    VALUES (1, 2, CURRENT_DATE + 14);
    INSERT INTO sert_detalle_prestamo (id_prestamo, id_ejemplar)
    VALUES (currval(pg_get_serial_sequence('sert_prestamo','id_prestamo')),
            (SELECT id_ejemplar FROM sert_ejemplar WHERE estado = 'DISPONIBLE' LIMIT 1));
  `);

  await rechazo('PF-19', `DELETE FROM sert_prestamo WHERE id_prestamo = 2`);

  await dueno.query('BEGIN');
  await dueno.query(`
    INSERT INTO sert_reserva (id_socio, id_libro, fecha_limite)
    VALUES (3, 1, CURRENT_DATE + 3)
  `);
  await dueno.query(`
    INSERT INTO sert_prestamo (id_socio, id_usuario, fecha_vencimiento)
    VALUES (3, 2, CURRENT_DATE + 14)
  `);
  const idPrestamo = await dueno.query(`SELECT currval(pg_get_serial_sequence('sert_prestamo','id_prestamo')) AS id`);
  await dueno.query(`
    INSERT INTO sert_detalle_prestamo (id_prestamo, id_ejemplar)
    VALUES ($1, (SELECT id_ejemplar FROM sert_ejemplar WHERE codigo_barras = 'BJ-001-2'))
  `, [idPrestamo.rows[0].id]);
  const reserva = await dueno.query(`
    SELECT estado FROM sert_reserva WHERE id_socio = 3 AND id_libro = 1 ORDER BY id_reserva DESC LIMIT 1
  `);
  anotar('PF-21 reserva=' + reserva.rows[0].estado);
  await dueno.query('ROLLBACK');

  await dueno.query("ALTER ROLE sert_app WITH LOGIN PASSWORD 'CAMBIAR_ESTA_CLAVE'");
  await dueno.query('GRANT sert_app TO CURRENT_USER');
  await dueno.query(`GRANT CONNECT ON DATABASE ${meta.rows[0].db} TO sert_app`);

  const url = new URL(process.env.DATABASE_URL);
  url.username = 'sert_app';
  url.password = 'CAMBIAR_ESTA_CLAVE';
  const limitado = cliente(url.toString());
  await limitado.connect();
  const del = await esperarError(() => limitado.query('DELETE FROM sert_rol WHERE id_rol = 1'));
  const upd = await esperarError(() => limitado.query("UPDATE sert_rol SET descripcion = 'x' WHERE id_rol = 1"));
  anotar('PF-20 DELETE ' + (del ? 'RECHAZADO: ' + del.split('\n')[0] : 'NO RECHAZADO'));
  anotar('PF-20 UPDATE ' + (upd ? 'RECHAZADO: ' + upd.split('\n')[0] : 'NO RECHAZADO'));
  await limitado.end();

  const despues = await dueno.query(`
    SELECT
      (SELECT count(*)::int FROM sert_libro) AS titulos,
      (SELECT count(*)::int FROM sert_ejemplar WHERE estado = 'DISPONIBLE') AS disponibles,
      (SELECT count(*)::int FROM sert_ejemplar) AS ejemplares,
      (SELECT count(*)::int FROM sert_socio WHERE estado = 'ACTIVO') AS socios,
      (SELECT count(*)::int FROM sert_prestamo WHERE estado = 'ABIERTO') AS abiertos,
      (SELECT count(DISTINCT id_prestamo)::int FROM sert_v_prestamos_vencidos) AS vencidos,
      (SELECT COALESCE(sum(monto), 0) FROM sert_multa WHERE estado = 'PENDIENTE') AS multa
  `);
  anotar('TABLA25_DESPUES ' + JSON.stringify(despues.rows[0]));
  await dueno.end();

  const destino = path.join(__dirname, 'evidencias');
  fs.mkdirSync(destino, { recursive: true });
  fs.writeFileSync(path.join(destino, 'resultado_pruebas.txt'), lineas.join('\n'), 'utf8');
})().catch((error) => {
  console.error('FALLO', error.message);
  process.exit(1);
});
