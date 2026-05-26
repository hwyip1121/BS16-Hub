// app/page.tsx — redirect to market
import { redirect } from "next/navigation";
export default function RootPage() { redirect("/market"); }
