import { Controller, Get, Header } from "@nestjs/common";
import { generateOpenApiDocument } from "./openapi.spec";

/**
 * Serves the generated OpenAPI 3.0 document. Intentionally public (no auth
 * guard) — it is the client-generation contract.
 */
@Controller()
export class OpenApiController {
  @Get("openapi.json")
  @Header("Content-Type", "application/json")
  index() {
    return generateOpenApiDocument();
  }
}
