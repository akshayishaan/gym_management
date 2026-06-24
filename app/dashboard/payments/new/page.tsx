import { redirect } from "next/navigation";

export default function NewPaymentPage() {
  redirect("/dashboard/payments");
}
