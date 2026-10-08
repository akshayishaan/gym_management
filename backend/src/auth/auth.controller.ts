import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
} from "@nestjs/common";
import { AuthService } from "./auth.service";
import type { LoginInput, RefreshInput, SignupInput } from "./auth.schemas";

@Controller("auth")
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post("login")
  @HttpCode(HttpStatus.OK)
  login(@Body() body: LoginInput) {
    return this.authService.login(body);
  }

  @Post("signup")
  @HttpCode(HttpStatus.CREATED)
  signup(@Body() body: SignupInput) {
    return this.authService.signup(body);
  }

  @Post("refresh")
  @HttpCode(HttpStatus.OK)
  refresh(@Body() body: RefreshInput) {
    return this.authService.refresh(body);
  }
}
