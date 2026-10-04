package com.icps.dto;

/**
 * Form-backing bean for the FNOL (First Notice of Loss) claim intake form
 * (Requirement 1.1).
 *
 * <p>{@code lossDate} is bound as a plain {@code String} in
 * {@code "yyyy-MM-dd"} format and parsed manually in
 * {@code ClaimIntakeController} rather than relying on an implicit
 * {@code @InitBinder} date editor, so that a malformed or missing date can
 * be surfaced as a field-specific validation message (Requirement 1.4)
 * instead of a binding exception.</p>
 */
public class FnolFormDto {

    private Long claimantId;
    private Long policyReferenceId;
    private String lossDate;
    private String lossDescription;

    public FnolFormDto() {
    }

    public Long getClaimantId() {
        return claimantId;
    }

    public void setClaimantId(Long claimantId) {
        this.claimantId = claimantId;
    }

    public Long getPolicyReferenceId() {
        return policyReferenceId;
    }

    public void setPolicyReferenceId(Long policyReferenceId) {
        this.policyReferenceId = policyReferenceId;
    }

    public String getLossDate() {
        return lossDate;
    }

    public void setLossDate(String lossDate) {
        this.lossDate = lossDate;
    }

    public String getLossDescription() {
        return lossDescription;
    }

    public void setLossDescription(String lossDescription) {
        this.lossDescription = lossDescription;
    }
}
