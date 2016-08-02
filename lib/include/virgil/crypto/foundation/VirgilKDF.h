/**
 * Copyright (C) 2015 Virgil Security Inc.
 *
 * Lead Maintainer: Virgil Security Inc. <support@virgilsecurity.com>
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     (1) Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *
 *     (2) Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in
 *     the documentation and/or other materials provided with the
 *     distribution.
 *
 *     (3) Neither the name of the copyright holder nor the names of its
 *     contributors may be used to endorse or promote products derived from
 *     this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ''AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef VIRGIL_CRYPTO_KDF_H
#define VIRGIL_CRYPTO_KDF_H

#include <string>
#include <memory>

#include <virgil/crypto/VirgilByteArray.h>
#include <virgil/crypto/foundation/asn1/VirgilAsn1Compatible.h>

namespace virgil { namespace crypto { namespace foundation {

/**
 * @brief Provides key derivation function algorithms.
 */
class VirgilKDF : public asn1::VirgilAsn1Compatible {
public:
    /**
     * @name Creation methods
     * @brief Object creation with specific key derivation function.
     */
    ///@{
    /**
     * @brief Configures with KDF1 (ISO-18033-2) algorithm.
     */
    static VirgilKDF kdf1();

    /**
     * @brief Configures with KDF1 (ISO-18033-2) algorithm.
     */
    static VirgilKDF kdf2();
    ///@}
    /**
     * @name Constructor / Destructor
     */
    ///@{
    /**
     * @brief Create object with undefined algorithm.
     * @warning SHOULD be used in conjunction with VirgilAsn1Compatible interface,
     *     i.e. VirgilKDF kdf = VirgilKDF().fromAsn1(asn1);
     */
    VirgilKDF();
    ///@}
    /**
     * @brief
     */
    /**
     * @name Info
     * @brief Provide detail information about object.
     */
    ///@{
    /**
     * @brief Returns name of the key derivation function.
     * @return Name of the key derivation function.
     */
    std::string name() const;
    ///@}
    /**
     * @name Process key derivation
     */
    ///@{
    /**
     * @brief Derive key from the given key material.
     *
     * @param in - input sequence (key material).
     * @param outSize - size of the output sequence.
     * @return Output sequence.
     */
    virgil::crypto::VirgilByteArray derive(const virgil::crypto::VirgilByteArray& in, size_t outSize);
    ///@}
    /**
     * @name VirgilAsn1Compatible implementation
     * @code
     * Marshalling format:
     *     KeyDerivationFunction ::= AlgorithmIdentifier {{ KDFAlgorithms }}
     *     KDFAlgorithms AlgorithmIdentifier ::= {
     *         { OID id-kdf-kdf1 PARMS HashFunction }  |
     *         { OID id-kdf-kdf2 PARMS HashFunction } ,
     *         ... -- additional algorithms ---
     *     }
     *
     *     HashFunction ::= AlgorithmIdentifier {{ HashAlgorithms }}
     *     HashAlgorithms AlgorithmIdentifier ::= {
     *         -- nist identifiers
     *         { OID id-sha1   PARMS NULL } |
     *         { OID id-sha256 PARMS NULL } |
     *         { OID id-sha384 PARMS NULL } |
     *         { OID id-sha512 PARMS NULL } ,
     *         ... -- additional algorithms ---
     *     }
     * @endcode
     */
    ///@{
    size_t asn1Write(asn1::VirgilAsn1Writer& asn1Writer, size_t childWrittenBytes = 0) const override;

    void asn1Read(asn1::VirgilAsn1Reader& asn1Reader) override;
    ///@}
public:
    //! @cond Doxygen_Suppress
    VirgilKDF(VirgilKDF&& rhs);

    VirgilKDF& operator=(VirgilKDF&& rhs);

    virtual ~VirgilKDF() noexcept;
    //! @endcond

private:
    template<typename TypeKDF, typename TypeMD>
    explicit VirgilKDF(TypeKDF kdf_type, TypeMD type_type);

    /**
     * @brief If internal state is not initialized with specific algorithm exception will be thrown.
     */
    void checkState() const;

private:
    class Impl;

    std::unique_ptr<Impl> impl_;
};

}}}

#endif /* VIRGIL_CRYPTO_KDF_H */
