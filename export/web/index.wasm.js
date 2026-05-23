export async function onRequest(context) {
  const object = await context.env.WASM_BUCKET.get("index.wasm");

  if (!object) {
    return new Response("WASM file not found", { status: 404 });
  }

  return new Response(object.body, {
    headers: {
      "Content-Type": "application/wasm",
      "Cross-Origin-Opener-Policy": "same-origin",
      "Cross-Origin-Embedder-Policy": "require-corp",
      "Cross-Origin-Resource-Policy": "cross-origin",
      "Cache-Control": "public, max-age=31536000, immutable",
    },
  });
}

