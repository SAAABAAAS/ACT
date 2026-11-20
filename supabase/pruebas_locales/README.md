# Pruebas locales del esquema

Comprueban que la seguridad de la base de datos funciona (12 pruebas): cada cliente ve solo su empresa, el rol `lectura` no puede editar, nadie se da permisos de equipo ACT, el agente no puede citar normativa sin verificar, no se aprueba una respuesta sin fuente y los archivos quedan aislados por empresa.

- `stub_supabase.sql` imita lo mínimo de Supabase (roles `anon`/`authenticated`, `auth.uid()`, Storage) para correr en un PostgreSQL normal. **No ejecutar en Supabase real.**
- `test_rls.sql` crea usuarios de prueba y compara resultado real vs. esperado (cada bloque indica qué debería pasar).

```bash
createdb act_test
for f in supabase/pruebas_locales/stub_supabase.sql supabase/migrations/*.sql supabase/seed.sql; do
  psql -d act_test -v ON_ERROR_STOP=1 -f "$f"
done
psql -d act_test -f supabase/pruebas_locales/test_rls.sql
```

Siguiente paso recomendado: pasar estas pruebas a [pgTAP](https://supabase.com/docs/guides/database/testing) para correrlas con `supabase test db`.
