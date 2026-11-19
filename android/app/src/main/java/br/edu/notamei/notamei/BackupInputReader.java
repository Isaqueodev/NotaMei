package br.edu.notamei.notamei;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

/** Bounded URI-stream reader; never resolves a content URI to a file path. */
public final class BackupInputReader {
    public static final int MAX_BYTES = 10 * 1024 * 1024;
    private BackupInputReader() {}
    public static final class TooLargeException extends IOException {}

    public static byte[] read(InputStream source) throws IOException {
        try (InputStream input = source) {
            ByteArrayOutputStream output = new ByteArrayOutputStream();
            byte[] buffer = new byte[8192];
            while (true) {
                int count = input.read(buffer, 0, Math.min(buffer.length, MAX_BYTES - output.size() + 1));
                if (count == -1) return output.toByteArray();
                if (count == 0) {
                    int single = input.read();
                    if (single == -1) return output.toByteArray();
                    if (output.size() == MAX_BYTES) throw new TooLargeException();
                    output.write(single);
                } else {
                    if (count > MAX_BYTES - output.size()) throw new TooLargeException();
                    output.write(buffer, 0, count);
                }
            }
        }
    }
}
