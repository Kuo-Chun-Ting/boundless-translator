# Screenshot selection inputs

Component tests pass these fixed images through production Vision recognition and the selection view in one process. The GUI fixture uses basic-text.png for native event routing. Tests do not draw inputs or exchange files between Apps.

| Image | Input and purpose |
| --- | --- |
| basic-text.png | English lines, Traditional Chinese and punctuation; 760 × 360. |
| scattered-labels.png | Battery status labels spread across three rows; select across each row before moving down. |
| ragged-rows.png | Three rows with different left edges; partial first/last rows and a complete middle row. |
| two-columns.png | Two labels on each row; horizontal reading order. |
| mixed-font-sizes.png | Different font sizes on one row. |
| no-text.png | Empty image; no selectable text. |
| battery-settings.jpeg | Real screenshot from the screenshot-demo source; selection on a real UI. |

Open the images to inspect the input. To change a layout, edit or replace the image, then update the affected test’s explicit coordinates and expected text. Selection calculation unit tests use small rectangles and literal strings instead of images.
