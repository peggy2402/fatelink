import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiResponse,
} from '@nestjs/swagger';

export function ApiAdminProtected() {
  return applyDecorators(ApiBearerAuth());
}

export function ApiAdminLogin() {
  return applyDecorators(
    ApiOperation({ summary: 'Dang nhap vao trang Quan tri' }),
    ApiResponse({
      status: 200,
      description: 'Dang nhap thanh cong, tra ve JWT token.',
    }),
    ApiResponse({ status: 401, description: 'Sai tai khoan hoac mat khau.' }),
  );
}

export function ApiGetSystemConfig() {
  return applyDecorators(ApiOperation({ summary: 'Lay cau hinh he thong' }));
}

export function ApiUpdateSystemConfig() {
  return applyDecorators(
    ApiOperation({ summary: 'Cap nhat cau hinh he thong' }),
  );
}

export function ApiAdminListUsers() {
  return applyDecorators(ApiOperation({ summary: 'Lay danh sach nguoi dung' }));
}

export function ApiAdminBanUser() {
  return applyDecorators(
    ApiOperation({ summary: 'Khoa hoac mo khoa tai khoan nguoi dung' }),
    ApiParam({ name: 'id', description: 'ID cua nguoi dung' }),
  );
}

export function ApiCheckAiStatus() {
  return applyDecorators(
    ApiOperation({ summary: 'Kiem tra trang thai cac AI provider' }),
  );
}

export function ApiGetAiModels() {
  return applyDecorators(
    ApiOperation({ summary: 'Lay danh sach model AI dang cau hinh' }),
  );
}

export function ApiCreateAiModel() {
  return applyDecorators(ApiOperation({ summary: 'Them moi mot model AI' }));
}

export function ApiUpdateAiModel() {
  return applyDecorators(
    ApiOperation({ summary: 'Cap nhat thong tin model AI' }),
    ApiParam({ name: 'id', description: 'ID cua AI model' }),
  );
}

export function ApiDeleteAiModel() {
  return applyDecorators(
    ApiOperation({ summary: 'Xoa model AI khoi he thong' }),
    ApiParam({ name: 'id', description: 'ID cua AI model' }),
  );
}

export function ApiReorderAiModels() {
  return applyDecorators(
    ApiOperation({ summary: 'Sap xep lai thu tu uu tien cua AI model' }),
  );
}

export function ApiAdminTestAiChat() {
  return applyDecorators(
    ApiOperation({
      summary: 'Chat gia lap tren dashboard de test system prompt',
    }),
  );
}

export function ApiSaveAdminLog() {
  return applyDecorators(
    ApiOperation({ summary: 'Ghi log dashboard admin xuong file' }),
  );
}

export function ApiDownloadAdminLogs() {
  return applyDecorators(
    ApiOperation({ summary: 'Tai toan bo file admin logs' }),
  );
}
