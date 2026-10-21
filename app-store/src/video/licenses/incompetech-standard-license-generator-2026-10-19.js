/*
 * gen-standard.js
 * In-browser port of the old Perl "license.pdf" generator (the Standard License).
 *
 * Produces the "AUTHORIZATION TO USE MUSIC COMPOSITION(S) AND RECORDING(S)" PDF.
 * Layout, coordinates, fonts and fee logic follow the original 1:1. The only
 * deliberate change: the date is rendered as text instead of the old
 * pre-rendered image tiles (m-1.jpg, 2026.jpg, etc.).
 *
 * generateStandardLicense({ pieces, company, name, title, licenseType })
 *   pieces      : array of track title strings (already selected, max 18)
 *   company     : licensee / production company (required)
 *   name        : additional licensee (optional)
 *   title       : title of the production (required)
 *   licenseType : 2 = commercial (includes the fee block); anything else omits it
 * returns a Uint8Array of PDF bytes.
 */
async function generateStandardLicense(opts) {
  const { drawLeft, drawRight, drawCenter, TextFlow, newDoc, embedSignature, drawHandwrittenDate, PAGE, MARGIN } = window.IncPDF;

  const pieces = opts.pieces || [];
  const company = opts.company || "";
  const name = opts.name || "";
  const prodTitle = opts.title || "";
  const licType = Number(opts.licenseType);

  const totalX = PAGE.w;      // 612
  const totalY = PAGE.h;      // 792
  const centerX = totalX / 2; // 306
  const margin = MARGIN;      // 36

  const ctx = await newDoc({
    title: "AUTHORIZATION TO USE MUSIC COMPOSITION(S) AND RECORDING(S)",
    author: "Kevin MacLeod",
    url: "http://incompetech.com/",
  });
  const { doc, fonts } = ctx;
  const page = doc.addPage([totalX, totalY]);
  const F = fonts;

  // ---------- Header ----------
  drawLeft(page, "incompetech.com", margin, totalY - (margin + 20), F.cgBold, 14);
  const addrYs = [35, 48, 61, 74];
  window.IncPDF.ADDRESS.forEach((line, i) =>
    drawLeft(page, line, margin, totalY - (margin + addrYs[i]), F.times, 11));

  // ---------- Tagline ----------
  drawCenter(page, "AUTHORIZATION TO USE MUSIC COMPOSITION(S) AND RECORDING(S)",
    centerX, totalY - (margin + 100), F.timesBold, 11);

  // ---------- Track list (two columns, numbered) ----------
  let yOff = 135;
  drawLeft(page, "Description of music compositions and recordings:",
    margin, totalY - (margin + yOff), F.helvBold, 11);

  for (let z = 0; z < pieces.length; z++) {
    if (z === 18) {                       // 19th+ piece: overflow marker
      yOff += 16;
      drawLeft(page, "ET AL", margin + 255, totalY - (margin + yOff), F.helvBold, 11);
      break;
    } else if (z <= 8) {                  // left column, rows 1-9
      yOff += 16;
      drawLeft(page, (z + 1) + ": " + pieces[z], margin + 25, totalY - (margin + yOff), F.helvBold, 11);
    } else {                              // right column, rows 10-18
      const y = totalY - (margin + (yOff - 144 + ((z - 8) * 16)));
      drawLeft(page, (z + 1) + ": " + pieces[z], margin + 255, y, F.helvBold, 11);
    }
  }
  yOff += 20;

  // ---------- Body ----------
  const bodyTop = totalY - yOff - 52; // note: matches original ($totalY - $yOff - 52)
  const flow = new TextFlow(page, { left: margin, right: totalX - margin, lineHeight: 17, top: bodyTop });

  // Paragraph 1 (grants clause) — inline font changes for company / name / title
  flow.paragraph(bodyTop, true);
  flow.add("For good and valuable consideration, receipt of which is hereby acknowledged, Owner (Kevin MacLeod) hereby grants to", F.times, 12);
  flow.add(" " + company, F.timesBold, 12);
  if (name) {
    flow.add(" and", F.times, 12);
    flow.add(" " + name, F.timesBold, 12);
  }
  flow.add(' ("Producer") the right, but not the obligation, to incorporate the music described above ("Property") in any manner Producer sees fit in the production tentatively entitled', F.times, 12);
  flow.add(" " + prodTitle, F.timesBold, 12);
  flow.add(' ("Program")  only and to use and authorize others to use the Property as so incorporated in the Program in the distribution, sale, licensing, marketing, advertising, promotion, merchandising, exhibition and other exploitation of the Program in perpetuity, worldwide in any media currently known or later devised. These rights are non-exclusive. All other rights are reserved by the Owner.', F.times, 12);
  let y = flow.end();

  // Paragraph 2 (commercial compensation) — only for license_type == 2
  if (licType === 2) {
    flow.paragraph(y - 26, true);
    flow.add("In full consideration of all rights granted herein, Producer agrees to pay to Owner and Owner agrees to accept, a fee of", F.times, 12);
    let fee;
    if (pieces.length <= 1) fee = " $__30__,";
    else if (pieces.length === 2) fee = " $__50__,";
    else fee = " $__" + (20 * pieces.length) + "__";
    flow.add(fee, F.timesBold, 12);
    flow.add(" US Dollars payable in full within ten (10) business days of initial airing or sale of the Program containing the Property provided mutual execution of this authorization has occurred.", F.times, 12);
    y = flow.end();
  }

  // Warranty paragraph (positioned 26 below the previous paragraph's last line)
  const yWarrant = y - 26;
  flow.paragraph(yWarrant, true);
  flow.add("Owner warrants and represents that Owner has the right to grant all rights granted herein and Producer and or Company's use of the Property as permitted herein will not infringe on the rights of any third party.", F.times, 12);
  flow.end();

  // Waiver paragraph (positioned 80 below the warranty paragraph's START — as in original)
  flow.paragraph(yWarrant - 54, true); // original used $y-80 vs $y-26 => 54 below warranty start
  flow.add("Owner waives claim to any compensation from Producer for use of items noted in this document. This release applies to any and all media and related usage in any future forms, and in any location.", F.times, 12);
  flow.end();

  // ---------- Signature block ----------
  drawRight(page, "Name:",      margin + 72, margin + 120, F.times, 11);
  drawLeft(page,  "Kevin MacLeod", margin + 92, margin + 120, F.times, 11);
  drawRight(page, "Signature:", margin + 72, margin + 80, F.times, 11);
  drawRight(page, "Date:",      margin + 72, margin + 40, F.times, 11);

  const sig = await embedSignature(ctx);
  page.drawImage(sig, { x: margin + 90, y: margin + 65, width: 147, height: 41 });

  // Handwritten date tiles (m-<mon>.jpg, <digit>.jpg, 1x/2x/3x.jpg, <year>.jpg),
  // exactly as the original license.pdf. Falls back to typed text if a tile is missing.
  await drawHandwrittenDate(ctx, page, { font: F.times, size: 11 });

  return await doc.save();
}

window.generateStandardLicense = generateStandardLicense;
