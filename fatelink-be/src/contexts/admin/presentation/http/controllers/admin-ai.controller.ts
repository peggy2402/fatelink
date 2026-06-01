import {
  Body,
  Controller,
  Delete,
  Get,
  Inject,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { AdminGuard } from '@contexts/auth/presentation/http/guards/admin.guard';
import { AI_APPLICATION_TOKENS } from '@contexts/ai/composition/ai.tokens';
import { ADMIN_APPLICATION_TOKENS } from '@contexts/admin/composition/admin.tokens';
import {
  ApiAdminProtected,
  ApiAdminTestAiChat,
  ApiCheckAiStatus,
  ApiCreateAiModel,
  ApiDeleteAiModel,
  ApiGetAiModels,
  ApiReorderAiModels,
  ApiUpdateAiModel,
} from '@contexts/admin/presentation/http/docs/admin.swagger';
import type { CheckAiProvidersStatusUseCase } from '@contexts/ai/application/usecases/check-ai-providers-status.usecase';
import type { AdminTestAiChatUseCase } from '@contexts/admin/application/usecases/admin-test-ai-chat.usecase';
import type { CreateAiModelUseCase } from '@contexts/admin/application/usecases/create-ai-model.usecase';
import type { DeleteAiModelUseCase } from '@contexts/admin/application/usecases/delete-ai-model.usecase';
import type { GetAiModelsUseCase } from '@contexts/admin/application/usecases/get-ai-models.usecase';
import type { ReorderAiModelsUseCase } from '@contexts/admin/application/usecases/reorder-ai-models.usecase';
import type { UpdateAiModelUseCase } from '@contexts/admin/application/usecases/update-ai-model.usecase';
import {
  CreateAiModelDto,
  ReorderAiModelsDto,
  TestAiChatDto,
  UpdateAiModelDto,
} from '../dtos/admin.request.dto';

@ApiTags('Admin AI')
@ApiAdminProtected()
@UseGuards(AdminGuard)
@Controller('admin')
export class AdminAiController {
  constructor(
    @Inject(AI_APPLICATION_TOKENS.checkProvidersStatus)
    private readonly checkAiProvidersStatusUseCase: CheckAiProvidersStatusUseCase,
    @Inject(ADMIN_APPLICATION_TOKENS.getAiModels)
    private readonly getAiModelsUseCase: GetAiModelsUseCase,
    @Inject(ADMIN_APPLICATION_TOKENS.createAiModel)
    private readonly createAiModelUseCase: CreateAiModelUseCase,
    @Inject(ADMIN_APPLICATION_TOKENS.updateAiModel)
    private readonly updateAiModelUseCase: UpdateAiModelUseCase,
    @Inject(ADMIN_APPLICATION_TOKENS.deleteAiModel)
    private readonly deleteAiModelUseCase: DeleteAiModelUseCase,
    @Inject(ADMIN_APPLICATION_TOKENS.reorderAiModels)
    private readonly reorderAiModelsUseCase: ReorderAiModelsUseCase,
    @Inject(ADMIN_APPLICATION_TOKENS.testAiChat)
    private readonly testAiChatUseCase: AdminTestAiChatUseCase,
  ) {}

  @Get('ai-status')
  @ApiCheckAiStatus()
  checkAiStatus() {
    return this.checkAiProvidersStatusUseCase.execute();
  }

  @Get('models')
  @ApiGetAiModels()
  getAiModels() {
    return this.getAiModelsUseCase.execute();
  }

  @Post('models')
  @ApiCreateAiModel()
  createAiModel(@Body() dto: CreateAiModelDto) {
    return this.createAiModelUseCase.execute(dto);
  }

  @Put('models/:id')
  @ApiUpdateAiModel()
  updateAiModel(@Param('id') id: string, @Body() dto: UpdateAiModelDto) {
    return this.updateAiModelUseCase.execute({ id, ...dto });
  }

  @Delete('models/:id')
  @ApiDeleteAiModel()
  deleteAiModel(@Param('id') id: string) {
    return this.deleteAiModelUseCase.execute({ id });
  }

  @Put('models/reorder')
  @ApiReorderAiModels()
  reorderAiModels(@Body() dto: ReorderAiModelsDto) {
    return this.reorderAiModelsUseCase.execute(dto);
  }

  @Post('ai-chat')
  @ApiAdminTestAiChat()
  testAiChat(@Body() dto: TestAiChatDto) {
    return this.testAiChatUseCase.execute({ message: dto.message });
  }
}
