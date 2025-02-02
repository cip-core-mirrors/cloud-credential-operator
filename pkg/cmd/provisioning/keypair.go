package provisioning

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/pem"
	"io"
	"log"
	"os"
	"path/filepath"

	"github.com/pkg/errors"
	"github.com/spf13/cobra"
)

const boundSAKeyFilename = "bound-service-account-signing-key.key"

func createKeys(prefixDir string) error {

	privateKeyFilePath := filepath.Join(prefixDir, privateKeyFile)
	publicKeyFilePath := filepath.Join(prefixDir, publicKeyFile)
	bitSize := 4096

	defer copyPrivateKeyForInstaller(privateKeyFilePath, prefixDir)

	_, err := os.Stat(privateKeyFilePath)
	if err == nil {
		log.Printf("Using existing RSA keypair found at %s", privateKeyFilePath)
		return nil
	}

	log.Print("Generating RSA keypair")
	privateKey, err := rsa.GenerateKey(rand.Reader, bitSize)
	if err != nil {
		return errors.Wrap(err, "failed to generate private key")
	}

	log.Print("Writing private key to ", privateKeyFilePath)
	f, err := os.Create(privateKeyFilePath)
	if err != nil {
		return errors.Wrap(err, "failed to create private key file")
	}

	err = pem.Encode(f, &pem.Block{
		Type:    "RSA PRIVATE KEY",
		Headers: nil,
		Bytes:   x509.MarshalPKCS1PrivateKey(privateKey),
	})
	f.Close()
	if err != nil {
		return errors.Wrap(err, "failed to write out private key data")
	}

	log.Print("Writing public key to ", publicKeyFilePath)
	f, err = os.Create(publicKeyFilePath)
	if err != nil {
		errors.Wrap(err, "failed to create public key file")
	}

	pubKeyBytes, err := x509.MarshalPKIXPublicKey(&privateKey.PublicKey)
	if err != nil {
		return errors.Wrap(err, "failed to generate public key from private")
	}

	err = pem.Encode(f, &pem.Block{
		Type:    "PUBLIC KEY",
		Headers: nil,
		Bytes:   pubKeyBytes,
	})
	f.Close()
	if err != nil {
		return errors.Wrap(err, "failed to write out public key data")
	}

	return nil
}

func copyPrivateKeyForInstaller(sourceFile, prefixDir string) {
	privateKeyForInstaller := filepath.Join(prefixDir, tlsDirName, boundSAKeyFilename)

	log.Print("Copying signing key for use by installer")
	from, err := os.Open(sourceFile)
	if err != nil {
		log.Fatalf("failed to open privatekeyfile for copying: %s", err)
	}
	defer from.Close()

	to, err := os.OpenFile(privateKeyForInstaller, os.O_RDWR|os.O_CREATE, 0600)
	if err != nil {
		log.Fatalf("failed to open/create target bound serviceaccount file: %s", err)
	}
	defer to.Close()

	_, err = io.Copy(to, from)
	if err != nil {
		log.Fatalf("failed to copy file: %s", err)
	}
}

func keyCmd(cmd *cobra.Command, args []string) {
	err := createKeys(CreateOpts.TargetDir)
	if err != nil {
		log.Fatal(err)
	}
}

// NewKeyProvision provides the "create key-pair" subcommand
func NewKeyProvision() *cobra.Command {
	keyProvisionCmd := &cobra.Command{
		Use: "key-pair",
		Run: keyCmd,
	}

	return keyProvisionCmd
}
