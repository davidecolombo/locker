package io.github.davidecolombo.locker;

import org.kohsuke.args4j.CmdLineParser;
import org.kohsuke.args4j.Option;

import javax.crypto.Cipher;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;
import java.io.ByteArrayOutputStream;
import java.io.DataInputStream;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Arrays;

@SuppressWarnings({"java:S112", "java:S6212"})
public class Locker {

    private static final String CIPHER_TRANSFORMATION = "AES/GCM/NoPadding";
    private static final String KDF_ALGORITHM         = "PBKDF2WithHmacSHA256";
    private static final String SECRET_KEY_ALGORITHM  = "AES";
    private static final int    KEY_BITS              = 256;
    private static final int    SALT_SIZE             = 16;
    private static final int    KDF_ITERATIONS        = 310_000;
    private static final SecureRandom RNG             = new SecureRandom();

    @Option(name = "--key", aliases = {"-k"})
    private String key;

    @Option(name = "--decrypt", aliases = {"-d"})
    private boolean decrypt;

    private static byte[] deriveKey(String password, byte[] salt) throws Exception {
        SecretKeyFactory factory = SecretKeyFactory.getInstance(KDF_ALGORITHM);
        PBEKeySpec spec = new PBEKeySpec(password.toCharArray(), salt, KDF_ITERATIONS, KEY_BITS);
        try {
            return factory.generateSecret(spec).getEncoded();
        } finally {
            spec.clearPassword();
        }
    }

    public static byte[] encrypt(byte[] clean, String key) throws Exception {
        Cipher cipher = Cipher.getInstance(CIPHER_TRANSFORMATION);
        int blockSize = cipher.getBlockSize();

        byte[] salt = new byte[SALT_SIZE];
        byte[] iv   = new byte[blockSize];
        RNG.nextBytes(salt);
        RNG.nextBytes(iv);

        byte[] keyBytes = deriveKey(key, salt);
        SecretKeySpec secretKeySpec = new SecretKeySpec(keyBytes, SECRET_KEY_ALGORITHM);
        try {
            cipher.init(Cipher.ENCRYPT_MODE, secretKeySpec, new GCMParameterSpec(blockSize * Byte.SIZE, iv));
            byte[] encrypted = cipher.doFinal(clean);

            byte[] output = new byte[SALT_SIZE + blockSize + encrypted.length];
            System.arraycopy(salt,      0, output, 0,                     SALT_SIZE);
            System.arraycopy(iv,        0, output, SALT_SIZE,             blockSize);
            System.arraycopy(encrypted, 0, output, SALT_SIZE + blockSize, encrypted.length);
            return output;
        } finally {
            Arrays.fill(keyBytes, (byte) 0);
            try { secretKeySpec.destroy(); } catch (Exception _) { /* SecretKeySpec.destroy() throws on Java 25 */ }
        }
    }

    public static byte[] decrypt(byte[] input, String key) throws Exception {
        Cipher cipher = Cipher.getInstance(CIPHER_TRANSFORMATION);
        int blockSize = cipher.getBlockSize();

        if (input.length <= SALT_SIZE + blockSize) {
            throw new IllegalArgumentException("Input is too short to be valid ciphertext");
        }

        byte[] salt = new byte[SALT_SIZE];
        System.arraycopy(input, 0, salt, 0, SALT_SIZE);

        byte[] iv = new byte[blockSize];
        System.arraycopy(input, SALT_SIZE, iv, 0, blockSize);

        int encryptedSize = input.length - SALT_SIZE - blockSize;
        byte[] encryptedBytes = new byte[encryptedSize];
        System.arraycopy(input, SALT_SIZE + blockSize, encryptedBytes, 0, encryptedSize);

        byte[] keyBytes = deriveKey(key, salt);
        SecretKeySpec secretKeySpec = new SecretKeySpec(keyBytes, SECRET_KEY_ALGORITHM);
        try {
            cipher.init(Cipher.DECRYPT_MODE, secretKeySpec, new GCMParameterSpec(blockSize * Byte.SIZE, iv));
            return cipher.doFinal(encryptedBytes);
        } finally {
            Arrays.fill(keyBytes, (byte) 0);
            try { secretKeySpec.destroy(); } catch (Exception _) { /* SecretKeySpec.destroy() throws on Java 25 */ }
        }
    }

    @SuppressWarnings("java:S106")
    public Locker(String[] args) throws Exception {
        new CmdLineParser(this).parseArgument(args);

        DataInputStream dis = new DataInputStream(System.in);
        ByteArrayOutputStream dataStream = new ByteArrayOutputStream();
        byte[] buffer = new byte[256];
        int len;

        if (key != null) {
            if (key.isEmpty()) throw new IllegalArgumentException();
            while ((len = dis.read(buffer, 0, 256)) != -1) dataStream.write(buffer, 0, len);
        } else {
            int passphraseLen = dis.readInt();
            if (passphraseLen <= 0) throw new IllegalArgumentException();
            byte[] passphraseBytes = new byte[passphraseLen];
            dis.readFully(passphraseBytes);
            key = new String(passphraseBytes, StandardCharsets.UTF_8);
            Arrays.fill(passphraseBytes, (byte) 0);
            while ((len = dis.read(buffer, 0, 256)) != -1) dataStream.write(buffer, 0, len);
        }

        System.out.write(decrypt
                ? decrypt(dataStream.toByteArray(), key)
                : encrypt(dataStream.toByteArray(), key));
    }

    public static void main(String[] args) throws Exception {
        new Locker(args);
    }
}
