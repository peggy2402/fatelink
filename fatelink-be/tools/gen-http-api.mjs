import fs from 'node:fs';
import path from 'node:path';
import inquirer from 'inquirer';

const projectRoot = process.cwd();
const srcRoot = path.join(projectRoot, 'src');
const contextsRoot = path.join(srcRoot, 'contexts');

function getContextTokensFile(context) {
  return path.join(contextsRoot, context, 'composition', `${context}.tokens.ts`);
}

function getContextTokensConstant(context) {
  return `${toPascalCase(context).toUpperCase()}_APPLICATION_TOKENS`;
}

function buildContextTokenAccessor(context, tokenKey) {
  return `${getContextTokensConstant(context)}.${tokenKey}`;
}

function parseCliArgs(argv) {
  const args = {};
  for (let index = 0; index < argv.length; index += 1) {
    const current = argv[index];
    if (!current.startsWith('--')) continue;

    const key = current.slice(2);
    const next = argv[index + 1];
    if (!next || next.startsWith('--')) {
      args[key] = true;
      continue;
    }

    args[key] = next;
    index += 1;
  }
  return args;
}

function read(filePath) {
  return fs.readFileSync(filePath, 'utf8');
}

function write(filePath, content) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, content, 'utf8');
}

function writeIfMissing(filePath, content) {
  if (fs.existsSync(filePath)) return;
  write(filePath, content);
}

function toPascalCase(value) {
  return value
    .split(/[^a-zA-Z0-9]+/)
    .filter(Boolean)
    .map((part) => part[0].toUpperCase() + part.slice(1))
    .join('');
}

function toCamelCase(value) {
  const pascal = toPascalCase(value);
  return pascal ? pascal[0].toLowerCase() + pascal.slice(1) : '';
}

function ensureNotExists(filePath, label) {
  if (fs.existsSync(filePath)) {
    throw new Error(`${label} already exists: ${filePath}`);
  }
}

function listDirectories(dirPath) {
  if (!fs.existsSync(dirPath)) return [];
  return fs
    .readdirSync(dirPath, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();
}

function listFiles(dirPath, suffix) {
  if (!fs.existsSync(dirPath)) return [];
  return fs
    .readdirSync(dirPath, { withFileTypes: true })
    .filter((entry) => entry.isFile() && entry.name.endsWith(suffix))
    .map((entry) => entry.name)
    .sort();
}

function firstOrThrow(items, message) {
  if (items.length === 0) {
    throw new Error(message);
  }

  return items[0];
}

function listHttpReadyContexts() {
  return listDirectories(contextsRoot)
    .filter((name) => name !== 'shared')
    .filter((name) => {
      const compositionDir = path.join(contextsRoot, name, 'composition');
      const providerFiles = listFiles(compositionDir, '.providers.ts');
      const contextModules = listFiles(compositionDir, '-context.module.ts');
      const controllerDir = path.join(
        contextsRoot,
        name,
        'presentation',
        'http',
        'controllers',
      );
      const hasHttpPresentation = fs.existsSync(controllerDir);
      return providerFiles.length > 0 && contextModules.length > 0 && hasHttpPresentation;
    });
}

function toKebabCase(value) {
  return String(value)
    .trim()
    .replace(/([a-z0-9])([A-Z])/g, '$1-$2')
    .replace(/[^a-zA-Z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .toLowerCase();
}

function parseDependencySpecs(raw) {
  if (!raw) return [];
  return String(raw)
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean)
    .map((item) => {
      const [paramName, typeName, tokenAccessor, importPath] = item.split(':');
      if (!paramName || !typeName || !tokenAccessor) {
        throw new Error(
          `Invalid dependency spec "${item}". Use paramName:TypeName:TOKEN_ACCESSOR[:importPath]`,
        );
      }

      return {
        paramName,
        typeName,
        tokenAccessor,
        importPath: importPath || null,
      };
    });
}

function getCopy(lang) {
  if (lang === 'vi') {
    return {
      apiTagFallback: 'Api',
      todoSummary: (name) => `TODO: mo ta ${name}`,
      dtoExample: 'TODO',
      useCaseNotImplemented: 'Chua cai dat',
    };
  }

  return {
    apiTagFallback: 'Api',
    todoSummary: (name) => `TODO: describe ${name}`,
    dtoExample: 'TODO',
    useCaseNotImplemented: 'Not implemented',
  };
}

function getPromptCopy(lang) {
  if (lang === 'vi') {
    return {
      scaffoldLanguage: 'Chon ngon ngu scaffold',
      generationMode: 'Chon kieu sinh API',
      createNewContextApi: 'Tao moi: tao context moi roi scaffold API',
      useExistingContextApi: 'Theo context co san: scaffold vao context da co',
      enterNewContextName: 'Nhap ten context moi (kebab-case)',
      existingContext: 'Chon context co san',
      controllerMode: 'Chon cach xu ly controller',
      createNewController: 'Tao controller moi',
      appendExistingController: 'Them vao controller cu',
      existingController: 'Chon controller cu',
      actionName: 'Nhap ten action (kebab-case)',
      useKebabCase: 'Dung kebab-case',
      httpMethod: 'Chon HTTP method',
      baseRoute: 'Nhap base route cua controller',
      baseRouteRequired: 'Base route la bat buoc',
      actionRoute: 'Nhap action route',
      actionRouteRequired: 'Action route la bat buoc',
      accessLevel: 'Chon muc truy cap endpoint',
      publicAccess: 'Public - khong can dang nhap',
      userAccess: 'User - can dang nhap',
      adminAccess: 'Admin - can token admin',
      generateDto: 'API nay co request DTO khong?',
      dependencyHint:
        'Dependency spec: paramName:TypeName:TOKEN_ACCESSOR[:importPath]',
    };
  }

  return {
    scaffoldLanguage: 'Select scaffold language',
    generationMode: 'Select API generation mode',
    createNewContextApi: 'Create new: create a new context then scaffold API',
    useExistingContextApi: 'Use existing context: scaffold into an existing context',
    enterNewContextName: 'Enter new context name (kebab-case)',
    existingContext: 'Select existing context',
    controllerMode: 'Select controller mode',
    createNewController: 'Create new controller',
    appendExistingController: 'Append to existing controller',
    existingController: 'Select existing controller',
    actionName: 'Enter action name (kebab-case)',
    useKebabCase: 'Use kebab-case',
    httpMethod: 'Select HTTP method',
    baseRoute: 'Enter controller base route',
    baseRouteRequired: 'Base route is required',
    actionRoute: 'Enter action route',
    actionRouteRequired: 'Action route is required',
    accessLevel: 'Select endpoint access level',
    publicAccess: 'Public - no authentication required',
    userAccess: 'User - authenticated user required',
    adminAccess: 'Admin - admin token required',
    generateDto: 'Does this API need a request DTO?',
    dependencyHint:
      'Dependency spec: paramName:TypeName:TOKEN_ACCESSOR[:importPath]',
  };
}

function insertImportIfMissing(source, importLine) {
  if (source.includes(importLine)) return source;

  const lines = source.split('\n');
  let insertAt = 0;
  while (insertAt < lines.length && lines[insertAt].startsWith('import ')) {
    insertAt += 1;
  }
  lines.splice(insertAt, 0, importLine);
  return lines.join('\n');
}

function appendProvider(
  source,
  context,
  tokenAccessor,
  useCaseClass,
  importPath,
  providerExportName,
  useCasesExportName,
  dependencies,
) {
  const importLine = `import { ${useCaseClass} } from '${importPath}';`;
  let next = insertImportIfMissing(source, importLine);
  next = insertImportIfMissing(
    next,
    `import { ${getContextTokensConstant(context)} } from './${context}.tokens';`,
  );

  for (const dependency of dependencies) {
    if (dependency.importPath) {
      next = insertImportIfMissing(
        next,
        `import type { ${dependency.typeName} } from '${dependency.importPath}';`,
      );
    }
  }

  const useFactoryParams = dependencies
    .map((dependency) => `${dependency.paramName}: ${dependency.typeName}`)
    .join(', ');
  const constructorArgs = dependencies
    .map((dependency) => dependency.paramName)
    .join(', ');
  const injectArgs = dependencies
    .map((dependency) => dependency.tokenAccessor)
    .join(', ');

  const providerEntry = `  {
    provide: ${tokenAccessor},
    useFactory: (${useFactoryParams}) => new ${useCaseClass}(${constructorArgs}),
    inject: [${injectArgs}],
  },`;

  const providersPattern = new RegExp(`(export const ${providerExportName}: Provider\\[] = \\[\\n)`);
  next = next.replace(providersPattern, (match, prefix) =>
    next.includes(`provide: ${tokenAccessor}`) ? match : `${prefix}${providerEntry}\n`,
  );

  const useCasesPattern = new RegExp(`export const ${useCasesExportName} = \\[([\\s\\S]*?)\\];`);
  next = next.replace(useCasesPattern, (match, inner) => {
    if (inner.includes(tokenAccessor)) return match;
    const trimmed = inner.trim();
    const nextItems = trimmed
      ? `\n  ${trimmed.replace(/,\s*$/, '')},\n  ${tokenAccessor},\n`
      : `\n  ${tokenAccessor},\n`;
    return `export const ${useCasesExportName} = [${nextItems}];`;
  });

  return next;
}

function appendControllerToContextModule(source, controllerClass, importPath) {
  const importLine = `import { ${controllerClass} } from '${importPath}';`;
  let next = insertImportIfMissing(source, importLine);

  next = next.replace(/controllers:\s*\[([\s\S]*?)\]/, (match, inner) => {
    if (inner.includes(controllerClass)) return match;

    const items = inner
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean);
    items.push(controllerClass);

    if (items.length === 1) {
      return `controllers: [${controllerClass}]`;
    }

    return `controllers: [\n    ${items.join(',\n    ')},\n  ]`;
  });

  return next;
}

function appendMethodToController(
  source,
  context,
  methodContent,
  methodDecoratorImport,
  needsBody,
  guard,
  dtoClass,
  dtoImportPath,
  useCaseClass,
  useCaseImportPath,
  useCaseProperty,
  tokenAccessor,
) {
  let next = source;
  next = insertImportIfMissing(
    next,
    `import type { ${useCaseClass} } from '${useCaseImportPath}';`,
  );
  if (needsBody) {
    next = insertImportIfMissing(next, "import { Body } from '@nestjs/common';");
  }
  next = insertImportIfMissing(
    next,
    `import { ${methodDecoratorImport} } from '@nestjs/common';`,
  );
  next = insertImportIfMissing(
    next,
    "import { ApiOperation } from '@nestjs/swagger';",
  );
  next = insertImportIfMissing(
    next,
    `import { ${getContextTokensConstant(context)} } from '@contexts/${context}/composition/${context}.tokens';`,
  );
  if (dtoClass) {
    next = insertImportIfMissing(
      next,
      `import { ${dtoClass} } from '${dtoImportPath}';`,
    );
  }
  if (guard === 'jwt') {
    next = insertImportIfMissing(
      next,
      "import { JwtAuthGuard } from '@contexts/auth/presentation/http/guards/jwt-auth.guard';",
    );
    next = insertImportIfMissing(next, "import { UseGuards } from '@nestjs/common';");
    next = insertImportIfMissing(next, "import { ApiBearerAuth } from '@nestjs/swagger';");
  }
  if (guard === 'admin') {
    next = insertImportIfMissing(
      next,
      "import { AdminGuard } from '@contexts/auth/presentation/http/guards/admin.guard';",
    );
    next = insertImportIfMissing(next, "import { UseGuards } from '@nestjs/common';");
    next = insertImportIfMissing(next, "import { ApiBearerAuth } from '@nestjs/swagger';");
  }

  if (!next.includes(`private readonly ${useCaseProperty}: ${useCaseClass}`)) {
    next = next.replace(
      /constructor\(([\s\S]*?)\)\s*\{/,
      (match, inner) => {
        const trimmed = inner.trim();
        const injection = `\n    @Inject(${tokenAccessor})\n    private readonly ${useCaseProperty}: ${useCaseClass},\n  `;
        if (!trimmed) {
          return `constructor(${injection}) {`;
        }

        return `constructor(\n${trimmed.replace(/^/gm, '    ')}${injection}) {`;
      },
    );
  }

  return next.replace(/\n}\s*$/, `\n${methodContent}\n}\n`);
}

function appendToken(source, group, tokenKey, tokenValue) {
  const pattern = /(\{\n[\s\S]*?)(\n\} as const;)/m;
  return source.replace(pattern, (match, head, tail) => {
    if (head.includes(`${tokenKey}:`)) return match;
    return `${head}\n  ${tokenKey}: '${tokenValue}',${tail}`;
  });
}

function buildControllerContent({
  context,
  controllerClass,
  useCaseClass,
  useCaseProperty,
  tokenAccessor,
  baseRoute,
  httpMethod,
  actionRoute,
  methodName,
  dtoClass,
  dtoImportPath,
  guard,
  actionName,
  lang,
}) {
  const copy = getCopy(lang);
  const decoratorByMethod = {
    get: 'Get',
    post: 'Post',
    put: 'Put',
    patch: 'Patch',
    delete: 'Delete',
  };

  const methodDecorator = decoratorByMethod[httpMethod];
  const routeLiteral = actionRoute ? `'${actionRoute}'` : '';
  const httpDecorator = routeLiteral
    ? `@${methodDecorator}(${routeLiteral})`
    : `@${methodDecorator}()`;
  const needsBody = Boolean(dtoClass) && !['get', 'delete'].includes(httpMethod);
  const bodyArg = needsBody ? `@Body() dto: ${dtoClass}` : '';
  const executeArg = needsBody ? 'dto' : '{}';

  const commonImports = ['Controller', 'Inject', methodDecorator];
  if (needsBody) commonImports.unshift('Body');
  if (guard !== 'none') commonImports.push('UseGuards');

  const swaggerImports = ['ApiOperation', 'ApiTags'];
  if (guard !== 'none') swaggerImports.unshift('ApiBearerAuth');

  const guardImportLine =
    guard === 'jwt'
      ? `import { JwtAuthGuard } from '@contexts/auth/presentation/http/guards/jwt-auth.guard';\n`
      : guard === 'admin'
        ? `import { AdminGuard } from '@contexts/auth/presentation/http/guards/admin.guard';\n`
        : '';

  const dtoImportLine = dtoClass
    ? `import { ${dtoClass} } from '${dtoImportPath}';\n`
    : '';

  const guardDecorator =
    guard === 'jwt'
      ? '@ApiBearerAuth()\n@UseGuards(JwtAuthGuard)\n'
      : guard === 'admin'
        ? '@ApiBearerAuth()\n@UseGuards(AdminGuard)\n'
        : '';

  return `import { ${commonImports.join(', ')} } from '@nestjs/common';
import { ${swaggerImports.join(', ')} } from '@nestjs/swagger';
${guardImportLine}import type { ${useCaseClass} } from '@contexts/${context}/application/usecases/${actionName}.usecase';
import { ${getContextTokensConstant(context)} } from '@contexts/${context}/composition/${context}.tokens';
${dtoImportLine}@ApiTags('${toPascalCase(context)}')
${guardDecorator}@Controller('${baseRoute}')
export class ${controllerClass} {
  constructor(
    @Inject(${tokenAccessor})
    private readonly ${useCaseProperty}: ${useCaseClass},
  ) {}

  ${httpDecorator}
  @ApiOperation({ summary: '${copy.todoSummary(methodName)}' })
  ${methodName}(${bodyArg}) {
    return this.${useCaseProperty}.execute(${executeArg});
  }
}
`;
}

function buildUseCaseContent(useCaseClass, dependencies, lang) {
  const copy = getCopy(lang);
  const importLines = dependencies
    .filter((dependency) => dependency.importPath)
    .map(
      (dependency) =>
        `import type { ${dependency.typeName} } from '${dependency.importPath}';`,
    )
    .join('\n');
  const constructorParams = dependencies
    .map(
      (dependency) =>
        `private readonly ${dependency.paramName}: ${dependency.typeName}`,
    )
    .join(',\n    ');
  const constructorBlock = constructorParams
    ? `  constructor(\n    ${constructorParams},\n  ) {}\n\n`
    : '';

  return `${importLines ? `${importLines}\n\n` : ''}export class ${useCaseClass} {
${constructorBlock}  execute(input: unknown) {
    void input;
    throw new Error('${copy.useCaseNotImplemented}');
  }
}
`;
}

function buildDtoContent(dtoClass, lang) {
  const copy = getCopy(lang);
  return `import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class ${dtoClass} {
  @ApiProperty({ example: '${copy.dtoExample}' })
  @IsString()
  @IsNotEmpty()
  value!: string;
}
`;
}

function detectProviderMeta(providerFileName) {
  const prefix = providerFileName.replace('.providers.ts', '');
  if (prefix === 'chat') {
    return {
      providerExportName: 'chatUseCaseProviders',
      useCasesExportName: 'chatUseCases',
    };
  }

  return {
    providerExportName: `${prefix}UseCaseProviders`,
    useCasesExportName: `${prefix}UseCases`,
  };
}

function appendContextModuleImport(source, contextClass, importPath) {
  const importLine = `import { ${contextClass} } from '${importPath}';`;
  let next = insertImportIfMissing(source, importLine);

  next = next.replace(/imports:\s*\[([\s\S]*?)\]/, (match, inner) => {
    if (inner.includes(contextClass)) return match;

    const items = inner
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean);
    items.push(contextClass);

    if (items.length === 1) {
      return `imports: [${contextClass}]`;
    }

    return `imports: [\n    ${items.join(',\n    ')},\n  ]`;
  });

  return next;
}

function ensureAuthSecurityImport(source) {
  const importLine =
    "import { AuthSecurityModule } from '@contexts/auth/composition/auth-security.module';";
  let next = insertImportIfMissing(source, importLine);

  next = next.replace(/imports:\s*\[([\s\S]*?)\]/, (match, inner) => {
    if (inner.includes('AuthSecurityModule')) return match;

    const items = inner
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean);
    items.push('AuthSecurityModule');

    if (items.length === 1) {
      return 'imports: [AuthSecurityModule]';
    }

    return `imports: [\n    ${items.join(',\n    ')},\n  ]`;
  });

  return next;
}

function ensureTokenGroup(source, tokenGroup) {
  void tokenGroup;
  return source;
}

function ensureContextSkeleton(contextName) {
  const context = toKebabCase(contextName);
  const contextPascal = toPascalCase(context);
  const contextRoot = path.join(contextsRoot, context);

  const applicationContractsDir = path.join(contextRoot, 'application', 'contracts');
  const applicationUsecasesDir = path.join(contextRoot, 'application', 'usecases');
  const presentationControllersDir = path.join(
    contextRoot,
    'presentation',
    'http',
    'controllers',
  );
  const presentationDtosDir = path.join(contextRoot, 'presentation', 'http', 'dtos');
  const compositionDir = path.join(contextRoot, 'composition');
  const infrastructureDir = path.join(contextRoot, 'infrastructure');

  fs.mkdirSync(applicationContractsDir, { recursive: true });
  fs.mkdirSync(applicationUsecasesDir, { recursive: true });
  fs.mkdirSync(presentationControllersDir, { recursive: true });
  fs.mkdirSync(presentationDtosDir, { recursive: true });
  fs.mkdirSync(compositionDir, { recursive: true });
  fs.mkdirSync(infrastructureDir, { recursive: true });

  writeIfMissing(
    getContextTokensFile(context),
    `export const ${getContextTokensConstant(context)} = {\n} as const;\n`,
  );

  writeIfMissing(
    path.join(applicationContractsDir, `${context}.contracts.ts`),
    'export {};\n',
  );

  writeIfMissing(
    path.join(compositionDir, `${context}.providers.ts`),
    `import type { Provider } from '@nestjs/common';

export const ${context}UseCaseProviders: Provider[] = [];

export const ${context}UseCases = [];
`,
  );

  writeIfMissing(
    path.join(compositionDir, `${context}-application.module.ts`),
    `import { Module } from '@nestjs/common';
import { ${contextPascal}InfrastructureModule } from '@contexts/${context}/infrastructure/${context}-infrastructure.module';
import { ${context}UseCaseProviders, ${context}UseCases } from './${context}.providers';

@Module({
  imports: [${contextPascal}InfrastructureModule],
  providers: ${context}UseCaseProviders,
  exports: ${context}UseCases,
})
export class ${contextPascal}ApplicationModule {}
`,
  );

  writeIfMissing(
    path.join(compositionDir, `${context}-context.module.ts`),
    `import { Module } from '@nestjs/common';
import { ${contextPascal}ApplicationModule } from './${context}-application.module';

@Module({
  imports: [${contextPascal}ApplicationModule],
  controllers: [],
})
export class ${contextPascal}ContextModule {}
`,
  );

  writeIfMissing(
    path.join(infrastructureDir, `${context}-infrastructure.module.ts`),
    `import { Module } from '@nestjs/common';

@Module({})
export class ${contextPascal}InfrastructureModule {}
`,
  );

  const primaryAdaptersFile = path.join(srcRoot, 'composition', 'primary-adapters.module.ts');
  write(
    primaryAdaptersFile,
    appendContextModuleImport(
      read(primaryAdaptersFile),
      `${contextPascal}ContextModule`,
      `@contexts/${context}/composition/${context}-context.module`,
    ),
  );

  return {
    context,
    providerFileName: `${context}.providers.ts`,
    contextModuleFileName: `${context}-context.module.ts`,
    tokenGroup: context,
  };
}

async function promptConfig() {
  const cliArgs = parseCliArgs(process.argv.slice(2));
  if (cliArgs.context) {
    return {
      context: cliArgs.context,
      providerFileName: cliArgs.provider,
      contextModuleFileName: cliArgs.contextModule,
      tokenGroup: cliArgs.tokenGroup,
      actionName: cliArgs.action,
      httpMethod: cliArgs.method,
      baseRoute: cliArgs.baseRoute,
      actionRoute: cliArgs.actionRoute,
      guard: cliArgs.guard ?? 'none',
      generateDto: cliArgs.dto === 'true' || cliArgs.dto === true,
      lang: cliArgs.lang ?? 'en',
      useExistingController: cliArgs.controllerFile ? 'existing' : 'new',
      controllerFileName: cliArgs.controllerFile ?? '',
      dependencies: parseDependencySpecs(cliArgs.dependencies),
    };
  }

  const contexts = listHttpReadyContexts();
  const { lang } = await inquirer.prompt([
    {
      type: 'select',
      name: 'lang',
      message: 'Chon ngon ngu scaffold / Select scaffold language',
      choices: [
        { name: 'Tieng Viet', value: 'vi' },
        { name: 'English', value: 'en' },
      ],
      default: 'vi',
    },
  ]);
  const promptCopy = getPromptCopy(lang);
  const bootstrapAnswers = await inquirer.prompt([
    {
      type: 'select',
      name: 'contextMode',
      message: promptCopy.generationMode,
      choices: [
        {
          name: promptCopy.createNewContextApi,
          value: 'new-context',
        },
        {
          name: promptCopy.useExistingContextApi,
          value: 'existing-context',
        },
      ],
      default: 'existing-context',
    },
  ]);

  let context;
  let providerFileName;
  let contextModuleFileName;
  let tokenGroup;
  const isNewContextMode = bootstrapAnswers.contextMode === 'new-context';

  if (isNewContextMode) {
    const { newContextName } = await inquirer.prompt([
      {
        type: 'input',
        name: 'newContextName',
        message: promptCopy.enterNewContextName,
        validate: (value) =>
          /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(value) || promptCopy.useKebabCase,
      },
    ]);

    const skeleton = ensureContextSkeleton(newContextName);
    context = skeleton.context;
    providerFileName = skeleton.providerFileName;
    contextModuleFileName = skeleton.contextModuleFileName;
    tokenGroup = skeleton.tokenGroup;
  } else {
    if (contexts.length === 0) {
      throw new Error('No existing HTTP context found.');
    }
    const existingContextAnswer = await inquirer.prompt([
      {
        type: 'select',
        name: 'context',
        message: promptCopy.existingContext,
        choices: contexts,
      },
    ]);

    context = existingContextAnswer.context;
  }

  const compositionDir = path.join(contextsRoot, context, 'composition');
  const controllerDir = path.join(
    contextsRoot,
    context,
    'presentation',
    'http',
    'controllers',
  );
  const providerFiles = listFiles(compositionDir, '.providers.ts');
  const contextModules = listFiles(compositionDir, '-context.module.ts');
  const controllerFiles = listFiles(controllerDir, '.controller.ts');

  if (providerFiles.length === 0) {
    throw new Error(`No provider file found for context "${context}"`);
  }

  if (contextModules.length === 0) {
    throw new Error(`No context module found for context "${context}"`);
  }

  const resolvedProviderFileName =
    providerFileName ?? firstOrThrow(providerFiles, `No provider file found for context "${context}"`);
  const resolvedContextModuleFileName =
    contextModuleFileName ??
    firstOrThrow(contextModules, `No context module found for context "${context}"`);
  const resolvedTokenGroup = tokenGroup ?? context;

  const answers = await inquirer.prompt([
    ...(!isNewContextMode
      ? [
          {
            type: 'select',
            name: 'useExistingController',
            message: promptCopy.controllerMode,
            choices: [
              { name: promptCopy.createNewController, value: 'new' },
              {
                name: promptCopy.appendExistingController,
                value: 'existing',
              },
            ],
            default: controllerFiles.length > 0 ? 'existing' : 'new',
          },
          {
            type: 'select',
            name: 'controllerFileName',
            message: promptCopy.existingController,
            choices: controllerFiles,
            when: (answersSoFar) =>
              answersSoFar.useExistingController === 'existing' && controllerFiles.length > 0,
          },
        ]
      : []),
    {
      type: 'input',
      name: 'actionName',
      message: promptCopy.actionName,
      validate: (value) =>
        /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(value) || promptCopy.useKebabCase,
    },
    {
      type: 'select',
      name: 'httpMethod',
      message: promptCopy.httpMethod,
      choices: ['get', 'post', 'put', 'patch', 'delete'].map((name) => ({
        name: name.toUpperCase(),
        value: name,
      })),
    },
    {
      type: 'input',
      name: 'baseRoute',
      message: promptCopy.baseRoute,
      default: context,
      validate: (value) => value.length > 0 || promptCopy.baseRouteRequired,
    },
    {
      type: 'input',
      name: 'actionRoute',
      message: promptCopy.actionRoute,
      default: (answersSoFar) => answersSoFar.actionName,
      validate: (value) => value.length > 0 || promptCopy.actionRouteRequired,
    },
    {
      type: 'select',
      name: 'guard',
      message: promptCopy.accessLevel,
      choices: [
        { name: promptCopy.publicAccess, value: 'none' },
        { name: promptCopy.userAccess, value: 'jwt' },
        { name: promptCopy.adminAccess, value: 'admin' },
      ],
    },
    {
      type: 'confirm',
      name: 'generateDto',
      message: promptCopy.generateDto,
      default: (answersSoFar) => !['get', 'delete'].includes(answersSoFar.httpMethod),
    },
    {
      type: 'input',
      name: 'dependenciesRaw',
      default: '',
      when: () => false,
    },
  ]);

  return {
    context,
    lang,
    providerFileName: resolvedProviderFileName,
    contextModuleFileName: resolvedContextModuleFileName,
    tokenGroup: resolvedTokenGroup,
    ...answers,
    useExistingController: isNewContextMode
      ? 'new'
      : (answers.useExistingController ?? 'new'),
    controllerFileName: isNewContextMode ? '' : (answers.controllerFileName ?? ''),
    dependencies: parseDependencySpecs(answers.dependenciesRaw),
  };
}

async function main() {
  if (process.argv.includes('--help')) {
    console.log('Interactive generator for HTTP API scaffolding in contexts/*');
    console.log('Run: npm run gen:http-api');
    console.log('');
    console.log('Interactive options now include:');
    console.log('- step 1: scaffold language');
    console.log('- step 2: new context or existing context');
    console.log('- controller mode: create new / append to existing');
    console.log('- dependency format supports optional import path');
    console.log('');
    console.log(
      'Non-interactive example:',
    );
    console.log(
      'node ./tools/gen-http-api.mjs --context support --provider support.providers.ts --contextModule support-context.module.ts --tokenGroup support --action list-faq --method get --baseRoute support --actionRoute faq --guard none --dto false --lang vi',
    );
    console.log('');
    console.log('Append into existing controller example:');
    console.log(
      'node ./tools/gen-http-api.mjs --context admin --provider admin.providers.ts --contextModule admin-context.module.ts --tokenGroup admin --action export-users --method post --baseRoute admin/users --actionRoute export --guard admin --dto true --lang en --controllerFile admin-users.controller.ts',
    );
    console.log('');
    console.log('Dependency example:');
    console.log(
      'node ./tools/gen-http-api.mjs --context users --provider users.providers.ts --contextModule users-context.module.ts --tokenGroup users --action sync-profile --method post --baseRoute users --actionRoute sync --guard jwt --dto true --dependencies userRepository:UserRepository:USER_REPOSITORY:@contexts/users/domain/repositories/user.repository',
    );
    process.exit(0);
  }

  const config = await promptConfig();
  const {
    context,
    providerFileName,
    contextModuleFileName,
    tokenGroup,
    actionName,
    httpMethod,
    baseRoute,
    actionRoute,
    guard,
    generateDto,
    lang,
    useExistingController,
    controllerFileName,
    dependencies,
  } = config;

  const actionPascal = toPascalCase(actionName);
  const actionCamel = toCamelCase(actionName);
  const useCaseClass = `${actionPascal}UseCase`;
  const controllerClass = `${actionPascal}Controller`;
  const dtoClass = `${actionPascal}RequestDto`;
  const tokenKey = actionCamel;
  const tokenAccessor = buildContextTokenAccessor(context, tokenKey);
  const tokenValue = `application.${tokenGroup}.${actionName}`;
  const { providerExportName, useCasesExportName } = detectProviderMeta(providerFileName);
  const contextTokensFile = getContextTokensFile(context);

  const useCaseFile = path.join(
    contextsRoot,
    context,
    'application',
    'usecases',
    `${actionName}.usecase.ts`,
  );
  const controllerDir = path.join(
    contextsRoot,
    context,
    'presentation',
    'http',
    'controllers',
  );
  const controllerFile = path.join(
    controllerDir,
    useExistingController === 'existing' ? controllerFileName : `${actionName}.controller.ts`,
  );
  const dtoFile = path.join(
    contextsRoot,
    context,
    'presentation',
    'http',
    'dtos',
    `${actionName}.request.dto.ts`,
  );

  ensureNotExists(useCaseFile, 'Use case file');
  if (useExistingController !== 'existing') {
    ensureNotExists(controllerFile, 'Controller file');
  }
  if (generateDto) {
    ensureNotExists(dtoFile, 'DTO file');
  }

  write(useCaseFile, buildUseCaseContent(useCaseClass, dependencies, lang));

  if (generateDto) {
    write(dtoFile, buildDtoContent(dtoClass, lang));
  }

  const needsBody = Boolean(generateDto) && !['get', 'delete'].includes(httpMethod);
  const methodDecoratorImport = {
    get: 'Get',
    post: 'Post',
    put: 'Put',
    patch: 'Patch',
    delete: 'Delete',
  }[httpMethod];
  const routeLiteral = actionRoute ? `'${actionRoute}'` : '';
  const httpDecorator = routeLiteral
    ? `@${methodDecoratorImport}(${routeLiteral})`
    : `@${methodDecoratorImport}()`;
  const guardDecorator =
    guard === 'jwt'
      ? `  @ApiBearerAuth()\n  @UseGuards(JwtAuthGuard)\n`
      : guard === 'admin'
        ? `  @ApiBearerAuth()\n  @UseGuards(AdminGuard)\n`
        : '';
  const methodContent = `\n  ${guardDecorator}${httpDecorator}\n  @ApiOperation({ summary: '${getCopy(lang).todoSummary(actionCamel)}' })\n  ${actionCamel}(${needsBody ? `@Body() dto: ${dtoClass}` : ''}) {\n    return this.${actionCamel}UseCase.execute(${needsBody ? 'dto' : '{}'});\n  }`;

  if (useExistingController === 'existing') {
    write(
      controllerFile,
      appendMethodToController(
        read(controllerFile),
        context,
        methodContent,
        methodDecoratorImport,
        needsBody,
        guard,
        generateDto ? dtoClass : '',
        `../dtos/${actionName}.request.dto`,
        useCaseClass,
        `@contexts/${context}/application/usecases/${actionName}.usecase`,
        `${actionCamel}UseCase`,
        tokenAccessor,
      ),
    );
  } else {
    write(
      controllerFile,
      buildControllerContent({
        context,
        controllerClass,
        useCaseClass,
        useCaseProperty: `${actionCamel}UseCase`,
        tokenAccessor,
        baseRoute,
        httpMethod,
        actionRoute,
        methodName: actionCamel,
        dtoClass: generateDto ? dtoClass : '',
        dtoImportPath: `../dtos/${actionName}.request.dto`,
        guard,
        actionName,
        lang,
      }),
    );
  }

  const providerFile = path.join(contextsRoot, context, 'composition', providerFileName);
  write(
    providerFile,
    appendProvider(
      read(providerFile),
      context,
      tokenAccessor,
      useCaseClass,
      `@contexts/${context}/application/usecases/${actionName}.usecase`,
      providerExportName,
      useCasesExportName,
      dependencies,
    ),
  );

  write(
    contextTokensFile,
    appendToken(read(contextTokensFile), tokenGroup, tokenKey, tokenValue),
  );

  const contextModuleFile = path.join(
    contextsRoot,
    context,
    'composition',
    contextModuleFileName,
  );
  if (useExistingController !== 'existing') {
    write(
      contextModuleFile,
      appendControllerToContextModule(
        read(contextModuleFile),
        controllerClass,
        `@contexts/${context}/presentation/http/controllers/${actionName}.controller`,
      ),
    );
  }

  if (guard !== 'none') {
    write(contextModuleFile, ensureAuthSecurityImport(read(contextModuleFile)));
  }

  console.log(`Generated ${actionName} for context ${context}`);
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
