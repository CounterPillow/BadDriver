import std.stdio;
import img;
import hidraw;


ubyte[] pixmap_to_lcd(in MonoImage px, ubyte threshold = 1) {
    auto buf = new ubyte[960];
    for(int row = 0; row < 5; row++) {
        for(int col = 0; col < 160; col++) {
            ubyte b = 0;
            b += (px.get(col, row * 8).v[0] >= threshold);
            b += (px.get(col, row * 8 + 1).v[0] >= threshold) << 1;
            b += (px.get(col, row * 8 + 2).v[0] >= threshold) << 2;
            b += (px.get(col, row * 8 + 3).v[0] >= threshold) << 3;
            b += (px.get(col, row * 8 + 4).v[0] >= threshold) << 4;
            b += (px.get(col, row * 8 + 5).v[0] >= threshold) << 5;
            b += (px.get(col, row * 8 + 6).v[0] >= threshold) << 6;
            b += (px.get(col, row * 8 + 7).v[0] >= threshold) << 7;
            buf[row * 160 + col] = b;
        }
    }
    // row 5, only 3 pixels per column
    for(int col = 0; col < 160; col++) {
        ubyte b = 0;
        b += (px.get(col, 5 * 8).v[0] >= threshold);
        b += (px.get(col, 5 * 8 + 1).v[0] >= threshold) << 1;
        b += (px.get(col, 5 * 8 + 2).v[0] >= threshold) << 2;
        buf[5 * 160 + col] = b;
    }
    return buf;
}

void send_data(hidraw_handle h, immutable ubyte[] lcdbuf) {
    ubyte[32] header = 0;
    header[0] = 0x03;
    h.f.rawWrite(header);
    h.f.rawWrite(lcdbuf);
    h.f.flush();
}
