import { Module } from "@nestjs/common";
import { MongoConnectionService } from "./mongo-connection.service";

@Module({
  providers: [MongoConnectionService],
  exports: [MongoConnectionService],
})
export class DatabaseModule {}
