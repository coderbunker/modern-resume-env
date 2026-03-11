import { join } from 'node:path';
import { existsSync } from 'node:fs';

/**
 * validate-env.ts
 * 
 * Part of modern-resume-env. This script validates the current environment variables
 * against a Zod schema defined in src/configSchema.ts of the current working directory.
 */

const SCHEMA_FILE = 'src/configSchema.ts';
const schemaPath = join(process.cwd(), SCHEMA_FILE);

if (!existsSync(schemaPath)) {
  // No schema found, nothing to validate.
  process.exit(0);
}

try {
  // Dynamically import the schema from the service repository.
  // Bun handles TypeScript files natively.
  const module = await import(schemaPath);
  
  // Standard convention: exported as 'configSchema' or as a default export.
  const configSchema = module.configSchema || module.default;

  if (!configSchema || typeof configSchema.safeParse !== 'function') {
    console.warn(`\x1b[33m⚠️  ${SCHEMA_FILE} found but no Zod schema "configSchema" exported.\x1b[0m`);
    process.exit(0);
  }

  // Validate the current process.env against the Zod schema.
  // This will check types, presence, and any other Zod constraints.
  const result = configSchema.safeParse(process.env);

  if (!result.success) {
    console.error(`\x1b[31m❌ Environment validation failed for ${SCHEMA_FILE}:\x1b[0m`);
    result.error.issues.forEach((issue: any) => {
      const path = issue.path.join('.') || '(root)';
      console.error(`   - \x1b[1m${path}\x1b[0m: ${issue.message}`);
    });
    process.exit(1);
  }

  console.log(`\x1b[32m✅ Environment validation passed against ${SCHEMA_FILE}.\x1b[0m`);
  process.exit(0);
} catch (error: any) {
  // Handle common errors gracefully
  if (error.message && (error.message.includes('Cannot find module "zod"') || error.message.includes('Cannot find module "@hono/zod-openapi"'))) {
    console.warn('\x1b[33m⚠️  Validation skipped: Zod dependencies not found. Have you run "bun install"?\x1b[0m');
    process.exit(0);
  }
  
  console.error(`\x1b[31m❌ Error loading or running config validation from ${SCHEMA_FILE}:\x1b[0m`);
  console.error(error.message || error);
  process.exit(1);
}
