import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Gym Manager",
    short_name: "Gym Manager",
    description: "Manage members, payments, and plans from your phone.",
    start_url: "/dashboard",
    display: "standalone",
    background_color: "#f7f2ec",
    theme_color: "#f05b3b",
    icons: [
      { src: "/icons/icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
      { src: "/icons/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
      { src: "/icons/icon-512-maskable.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
    ],
  };
}
