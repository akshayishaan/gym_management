import { Global, Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { MongoConfigService } from "./mongo-config.service";

/**
 * Loads environment variables once for the whole app and exposes the
 * MongoConfigService that resolves the shared Mongo / auth / cache settings.
 */
@Global()
@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true })],
  providers: [MongoConfigService],
  exports: [MongoConfigService],
})
export class AppConfigModule {}
