// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";

// https://astro.build/config
export default defineConfig({
  site: "https://owt.lunicorn-lab.de",
  integrations: [
    starlight({
      title: "OpenWorktimeTracker",
      tagline: "Automatic worktime tracking for macOS",
      logo: {
        src: "./src/assets/logo.svg",
        alt: "OpenWorktimeTracker Logo",
      },
      social: [
        {
          icon: "github",
          label: "GitHub",
          href: "https://github.com/64x-lunicorn/OpenWorktimeTracker",
        },
      ],
      customCss: ["./src/styles/custom.css"],
      head: [
        {
          tag: "meta",
          attrs: {
            property: "og:image",
            content: "https://owt.lunicorn-lab.de/og-image.png",
          },
        },
      ],
      editLink: {
        baseUrl:
          "https://github.com/64x-lunicorn/OpenWorktimeTracker/edit/main/docs/",
      },
      sidebar: [
        {
          label: "Getting Started",
          items: [
            { label: "Installation", slug: "getting-started/installation" },
            { label: "Quick Start", slug: "getting-started/quick-start" },
          ],
        },
        {
          label: "Features",
          items: [
            { label: "Overview", slug: "features/overview" },
            { label: "Break Calculation (ArbZG)", slug: "features/breaks" },
            { label: "Idle Detection", slug: "features/idle-detection" },
            { label: "Workday Detection", slug: "features/workday-detection" },
            { label: "Notifications", slug: "features/notifications" },
            { label: "Data & Export", slug: "features/data" },
          ],
        },
        {
          label: "Configuration",
          items: [
            { label: "Settings", slug: "configuration/settings" },
            { label: "Auto-Updates (Sparkle)", slug: "configuration/sparkle" },
          ],
        },
        {
          label: "Architecture",
          items: [
            { label: "System Overview", slug: "architecture/overview" },
            { label: "State Machine", slug: "architecture/state-machine" },
            { label: "CI/CD Pipeline", slug: "architecture/cicd" },
          ],
        },
        {
          label: "Development",
          items: [
            { label: "Build from Source", slug: "development/build" },
            { label: "Contributing", slug: "development/contributing" },
            { label: "Changelog", slug: "development/changelog" },
          ],
        },
      ],
    }),
  ],
});
