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

function toKebabCase(value) {
  return String(value)
    .trim()
    .replace(/([a-z0-9])([A-Z])/g, '$1-$2')
    .replace(/[^a-zA-Z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .toLowerCase();
}

function listWsReadyContexts() {
  return listDirectories(contextsRoot)
    .filter((name) => name !== 'shared')
    .filter((name) => {
      const gatewayDir = path.join(
        contextsRoot,
        name,
        'presentation',
        'websocket',
        'gateways',
      );
      return listFiles(gatewayDir, '.gateway.ts').length > 0;
    });
}

function getCopy(lang) {
  if (lang === 'vi') {
    return {
      useCaseNotImplemented: 'Chua cai dat',
      wsError: 'Khong the xu ly yeu cau luc nay, ban thu lai sau nhe!',
    };
  }

  return {
    useCaseNotImplemented: 'Not implemented',
    wsError: 'Unable to process the request right now. Please try again later.',
  };
}

function getPromptCopy(lang) {
  if (lang === 'vi') {
    return {
      scaffoldLanguage: 'Chon ngon ngu scaffold',
      generationMode: 'Chon kieu sinh websocket API',
      createNewContextApi: 'Tao moi: tao context moi roi scaffold websocket API',
      useExistingContextApi: 'Theo context co san: scaffold vao context da co',
      enterNewContextName: 'Nhap ten context moi (kebab-case)',
      existingContext: 'Chon context co san',
      existingGateway: 'Chon gateway hien co',
      eventName: 'Nhap ten event client gui len',
      actionName: 'Nhap ten action (kebab-case)',
      useKebabCase: 'Dung kebab-case',
      responseEvent: 'Nhap ten event server tra ve',
      payloadFields: 'Nhap cac field payload (name:type, cach nhau boi dau phay)',
      payloadFieldsHint: 'Vi du: messageId:string,partnerId:string',
    };
  }

  return {
    scaffoldLanguage: 'Select scaffold language',
    generationMode: 'Select websocket API generation mode',
    createNewContextApi: 'Create new: create a new context then scaffold websocket API',
    useExistingContextApi: 'Use existing context: scaffold into an existing context',
    enterNewContextName: 'Enter new context name (kebab-case)',
    existingContext: 'Select existing context',
    existingGateway: 'Select existing gateway',
    eventName: 'Enter client event name',
    actionName: 'Enter action name (kebab-case)',
    useKebabCase: 'Use kebab-case',
    responseEvent: 'Enter server response event name',
    payloadFields: 'Enter payload fields (name:type, comma-separated)',
    payloadFieldsHint: 'Example: messageId:string,partnerId:string',
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

function appendTypeAlias(source, aliasName, aliasBody) {
  if (source.includes(`type ${aliasName} =`)) return source;

  const marker = 'type InterServerEvents = Record<string, never>;';
  if (!source.includes(marker)) {
    throw new Error(
      `Cannot append websocket event type "${aliasName}". Marker not found.`,
    );
  }

  return source.replace(marker, `type ${aliasName} = ${aliasBody};\n\n${marker}`);
}

function appendEventToEventMap(source, eventMapName, eventName, eventSignature) {
  const pattern = new RegExp(`(type ${eventMapName} = \\{[\\s\\S]*?)(\\n\\};)`, 'm');
  return source.replace(pattern, (match, head, tail) => {
    if (head.includes(`${eventName}:`)) return match;
    return `${head}\n  ${eventName}: ${eventSignature};${tail}`;
  });
}

function appendGatewayHandler(source, importLines, handlerContent) {
  let next = source;
  for (const importLine of importLines) {
    next = insertImportIfMissing(next, importLine);
  }

  if (next.includes(handlerContent.trim())) {
    return next;
  }

  return next.replace(/\n}\s*$/, `\n${handlerContent}\n}\n`);
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

    return items.length === 1
      ? `imports: [${contextClass}]`
      : `imports: [\n    ${items.join(',\n    ')},\n  ]`;
  });

  return next;
}

function ensureTokenGroup(source, tokenGroup) {
  void tokenGroup;
  return source;
}

function ensureWsContextSkeleton(contextName) {
  const context = toKebabCase(contextName);
  const contextPascal = toPascalCase(context);
  const contextRoot = path.join(contextsRoot, context);
  const applicationContractsDir = path.join(contextRoot, 'application', 'contracts');
  const applicationUsecasesDir = path.join(contextRoot, 'application', 'usecases');
  const compositionDir = path.join(contextRoot, 'composition');
  const infrastructureDir = path.join(contextRoot, 'infrastructure');
  const gatewayDir = path.join(contextRoot, 'presentation', 'websocket', 'gateways');
  const primaryAdaptersFile = path.join(srcRoot, 'composition', 'primary-adapters.module.ts');

  fs.mkdirSync(applicationContractsDir, { recursive: true });
  fs.mkdirSync(applicationUsecasesDir, { recursive: true });
  fs.mkdirSync(compositionDir, { recursive: true });
  fs.mkdirSync(infrastructureDir, { recursive: true });
  fs.mkdirSync(gatewayDir, { recursive: true });

  writeIfMissing(
    path.join(applicationContractsDir, `${context}.commands.ts`),
    'export {};\n',
  );
  writeIfMissing(
    getContextTokensFile(context),
    `export const ${getContextTokensConstant(context)} = {\n} as const;\n`,
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
import { ${contextPascal}Gateway } from '@contexts/${context}/presentation/websocket/gateways/${context}.gateway';
import { ${contextPascal}ApplicationModule } from './${context}-application.module';

@Module({
  imports: [${contextPascal}ApplicationModule],
  providers: [${contextPascal}Gateway],
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
  writeIfMissing(
    path.join(gatewayDir, `${context}.gateway.ts`),
    `import { Inject, Logger } from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import type { Server, Socket } from 'socket.io';

type ClientToServerEvents = {};
type ServerToClientEvents = {};
type InterServerEvents = Record<string, never>;
type SocketData = Record<string, never>;
type ${contextPascal}Socket = Socket<
  ClientToServerEvents,
  ServerToClientEvents,
  InterServerEvents,
  SocketData
>;

@WebSocketGateway()
export class ${contextPascal}Gateway {
  private readonly logger = new Logger(${contextPascal}Gateway.name);

  @WebSocketServer()
  server!: Server<ClientToServerEvents, ServerToClientEvents>;

  constructor() {}
}
`,
  );

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
    gatewayFileName: `${context}.gateway.ts`,
  };
}

function buildUseCaseContent(context, useCaseClass, payloadTypeName, lang) {
  const copy = getCopy(lang);
  return `import type { ${payloadTypeName} } from '@contexts/${context}/application/contracts/${context}.commands';

export class ${useCaseClass} {
  execute(input: ${payloadTypeName}) {
    void input;
    throw new Error('${copy.useCaseNotImplemented}');
  }
}
`;
}

function appendPayloadContract(source, payloadTypeName, fields) {
  if (source.includes(`export interface ${payloadTypeName}`)) return source;

  const fieldLines = fields
    .map(({ name, type }) => `  ${name}${type.endsWith('?') ? '' : ''}: ${type};`)
    .join('\n');

  return `${source.trimEnd()}\n\nexport interface ${payloadTypeName} {\n${fieldLines}\n}\n`;
}

function parseFieldSpecs(raw) {
  if (!raw) return [];
  return String(raw)
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean)
    .map((item) => {
      const [name, type] = item.split(':');
      if (!name || !type) {
        throw new Error(`Invalid field spec "${item}". Use name:type`);
      }
      return { name, type };
    });
}

function buildPayloadTypeLiteral(fields) {
  if (fields.length === 0) {
    return '{ }';
  }

  return `{\n${fields.map((field) => `  ${field.name}: ${field.type};`).join('\n')}\n}`;
}

function buildHandlerContent({
  eventName,
  handlerName,
  payloadTypeName,
  useCaseClass,
  useCaseProperty,
  responseEventName,
  socketTypeName,
  lang,
}) {
  const copy = getCopy(lang);
  return `
  @SubscribeMessage('${eventName}')
  async ${handlerName}(
    @ConnectedSocket() client: ${socketTypeName},
    @MessageBody() payload: ${payloadTypeName},
  ) {
    try {
      const result = await this.${useCaseProperty}.execute(payload);
      client.emit('${responseEventName}', result);
    } catch (error: unknown) {
      this.logger.error(
        'Failed to handle websocket event ${eventName}',
        error instanceof Error ? error.stack || error.message : String(error),
      );
      client.emit('errorMessage', {
        message: '${copy.wsError}',
      });
    }
  }`;
}

function appendProvider(source, context, tokenAccessor, useCaseClass, actionName) {
  const providerExportName = `${context}UseCaseProviders`;
  const useCasesExportName = `${context}UseCases`;
  let next = insertImportIfMissing(
    source,
    `import { ${useCaseClass} } from '@contexts/${context}/application/usecases/${actionName}.usecase';`,
  );
  next = insertImportIfMissing(
    next,
    `import { ${getContextTokensConstant(context)} } from './${context}.tokens';`,
  );
  next = next.replace(
    new RegExp(`(export const ${providerExportName}: Provider\\[] = \\[\\n)`),
    (match, prefix) =>
      next.includes(`provide: ${tokenAccessor}`)
        ? match
        : `${prefix}  {\n    provide: ${tokenAccessor},\n    useFactory: () => new ${useCaseClass}(),\n    inject: [],\n  },\n`,
  );
  next = next.replace(
    new RegExp(`export const ${useCasesExportName} = \\[([\\s\\S]*?)\\];`),
    (match, inner) => {
      if (inner.includes(tokenAccessor)) return match;
      const trimmed = inner.trim();
      const nextItems = trimmed
        ? `\n  ${trimmed.replace(/,\s*$/, '')},\n  ${tokenAccessor},\n`
        : `\n  ${tokenAccessor},\n`;
      return `export const ${useCasesExportName} = [${nextItems}];`;
    },
  );
  return next;
}

async function promptConfig() {
  const args = parseCliArgs(process.argv.slice(2));
  if (args.context && args.gateway && args.event && args.action) {
    return {
      context: args.context,
      gatewayFileName: args.gateway,
      eventName: args.event,
      actionName: args.action,
      responseEventName: args.responseEvent ?? `${toCamelCase(args.action)}Result`,
      requestFields: parseFieldSpecs(args.requestFields),
      lang: args.lang ?? 'en',
    };
  }

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
  const { contextMode } = await inquirer.prompt([
    {
      type: 'select',
      name: 'contextMode',
      message: promptCopy.generationMode,
      choices: [
        { name: promptCopy.createNewContextApi, value: 'new-context' },
        { name: promptCopy.useExistingContextApi, value: 'existing-context' },
      ],
      default: 'existing-context',
    },
  ]);

  let context;
  let gatewayFileName;
  if (contextMode === 'new-context') {
    const { newContextName } = await inquirer.prompt([
      {
        type: 'input',
        name: 'newContextName',
        message: promptCopy.enterNewContextName,
        validate: (value) =>
          /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(value) || promptCopy.useKebabCase,
      },
    ]);
    const skeleton = ensureWsContextSkeleton(newContextName);
    context = skeleton.context;
    gatewayFileName = skeleton.gatewayFileName;
  } else {
    const contexts = listWsReadyContexts();
    if (contexts.length === 0) {
      throw new Error('No existing websocket context found.');
    }
    const existing = await inquirer.prompt([
      {
        type: 'select',
        name: 'context',
        message: promptCopy.existingContext,
        choices: contexts,
      },
    ]);
    context = existing.context;
    const gatewayDir = path.join(
      contextsRoot,
      context,
      'presentation',
      'websocket',
      'gateways',
    );
    const gatewayFiles = listFiles(gatewayDir, '.gateway.ts');
    if (gatewayFiles.length === 0) {
      throw new Error(`No gateway file found for context "${context}"`);
    }
    const gatewayAnswer = await inquirer.prompt([
      {
        type: 'select',
        name: 'gatewayFileName',
        message: promptCopy.existingGateway,
        choices: gatewayFiles,
      },
    ]);
    gatewayFileName = gatewayAnswer.gatewayFileName;
  }

  const answers = await inquirer.prompt([
    {
      type: 'input',
      name: 'eventName',
      message: promptCopy.eventName,
      validate: (value) => value.trim().length > 0 || promptCopy.eventName,
    },
    {
      type: 'input',
      name: 'actionName',
      message: promptCopy.actionName,
      validate: (value) =>
        /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(value) || promptCopy.useKebabCase,
    },
    {
      type: 'input',
      name: 'responseEventName',
      message: promptCopy.responseEvent,
      default: (answersSoFar) => `${toCamelCase(answersSoFar.actionName)}Result`,
    },
    {
      type: 'input',
      name: 'requestFieldsRaw',
      message: promptCopy.payloadFields,
      default: '',
    },
  ]);

  return {
    context,
    gatewayFileName,
    eventName: answers.eventName,
    actionName: answers.actionName,
    responseEventName: answers.responseEventName,
    requestFields: parseFieldSpecs(answers.requestFieldsRaw),
    lang,
  };
}

async function main() {
  const args = parseCliArgs(process.argv.slice(2));

  if (args.help) {
    console.log('WebSocket scaffolding for existing gateways');
    console.log('Run: npm run gen:ws-api');
    console.log('');
    console.log('Interactive options now include:');
    console.log('- scaffold language');
    console.log('- new context or existing context');
    console.log('- existing gateway selection only when needed');
    console.log('');
    console.log(
      'Non-interactive example:',
    );
    console.log(
      'node ./tools/gen-ws-api.mjs --context chat --gateway chat.gateway.ts --event mark-read --action mark-read --requestFields messageId:string,partnerId:string --responseEvent markReadResult --lang en',
    );
    process.exit(0);
  }

  const config = await promptConfig();
  const { context, gatewayFileName, eventName, actionName, responseEventName, requestFields, lang } = config;

  const actionPascal = toPascalCase(actionName);
  const actionCamel = toCamelCase(actionName);
  const contextPascal = toPascalCase(context);
  const payloadTypeName = `${actionPascal}Payload`;
  const useCaseClass = `${actionPascal}UseCase`;
  const handlerName = `handle${actionPascal}`;
  const useCaseProperty = `${actionCamel}UseCase`;
  const tokenAccessor = buildContextTokenAccessor(context, actionCamel);
  const tokenValue = `application.${context}.${actionName}`;
  const socketTypeName = `${contextPascal}Socket`;

  const contractsFile = path.join(
    contextsRoot,
    context,
    'application',
    'contracts',
    `${context}.commands.ts`,
  );
  const useCaseFile = path.join(
    contextsRoot,
    context,
    'application',
    'usecases',
    `${actionName}.usecase.ts`,
  );
  const providerFile = path.join(
    contextsRoot,
    context,
    'composition',
    `${context}.providers.ts`,
  );
  const gatewayFile = path.join(
    contextsRoot,
    context,
    'presentation',
    'websocket',
    'gateways',
    gatewayFileName,
  );
  const contextTokensFile = getContextTokensFile(context);

  ensureNotExists(useCaseFile, 'Use case file');

  const updatedContracts = appendPayloadContract(
    read(contractsFile),
    payloadTypeName,
    requestFields,
  );
  write(contractsFile, updatedContracts);

  write(useCaseFile, buildUseCaseContent(context, useCaseClass, payloadTypeName, lang));

  write(providerFile, appendProvider(read(providerFile), context, tokenAccessor, useCaseClass, actionName));

  const nextTokens = read(contextTokensFile).replace(
    /(\{\n[\s\S]*?)(\n\} as const;)/m,
    (match, head, tail) => {
      if (head.includes(`${actionCamel}:`)) return match;
      return `${head}\n  ${actionCamel}: '${tokenValue}',${tail}`;
    },
  );
  write(contextTokensFile, nextTokens);

  let gatewaySource = read(gatewayFile);
  gatewaySource = appendTypeAlias(
    gatewaySource,
    payloadTypeName,
    buildPayloadTypeLiteral(requestFields),
  );
  gatewaySource = appendEventToEventMap(
    gatewaySource,
    'ClientToServerEvents',
    eventName,
    `(payload: ${payloadTypeName}) => void`,
  );
  gatewaySource = appendEventToEventMap(
    gatewaySource,
    'ServerToClientEvents',
    responseEventName,
    '(payload: unknown) => void',
  );
  gatewaySource = appendGatewayHandler(
    gatewaySource,
    [
      `import type { ${useCaseClass} } from '@contexts/${context}/application/usecases/${actionName}.usecase';`,
    ],
    buildHandlerContent({
      eventName,
      handlerName,
      payloadTypeName,
      useCaseClass,
      useCaseProperty,
      responseEventName,
      socketTypeName,
      lang,
    }),
  );

  if (!gatewaySource.includes(`private readonly ${useCaseProperty}: ${useCaseClass}`)) {
    gatewaySource = gatewaySource.replace(
      /constructor\(([\s\S]*?)\)\s*\{/,
      (match, inner) => {
        const trimmed = inner.trim();
        const injection = `\n    @Inject(${tokenAccessor})\n    private readonly ${useCaseProperty}: ${useCaseClass},\n  `;
        return trimmed
          ? `constructor(\n${trimmed.replace(/^/gm, '    ')}${injection}) {`
          : `constructor(${injection}) {`;
      },
    );
  }

  write(gatewayFile, gatewaySource);

  console.log(`Generated websocket action ${actionName} for context ${context}`);
}

try {
  await main();
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}
