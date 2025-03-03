const { v4: uuid } = require('uuid')

const { normalizePhone } = require('@condo/domains/common/utils/phone')
const { TELEGRAM_IDP_TYPE } = require('@condo/domains/user/constants/common')
const {
    User,
    UserExternalIdentity,
} = require('@condo/domains/user/utils/serverSchema')

const dv = 1
const sender = { dv, fingerprint: 'telegram-auth-user-external-identity' }

const linkUser = async (context, user, userInfo) => {
    const payload = {
        dv,
        sender,
        user: { connect: { id: user.id } },
        identityId: String(userInfo.userId),
        identityType: TELEGRAM_IDP_TYPE,
        meta: userInfo,
    }
    console.error(payload)
    await UserExternalIdentity.create(context, payload)

    return user
}

const registerUser = async (context, userInfo, userType) => {
    const normalizedPhone = normalizePhone(userInfo.phoneNumber)
    const password = uuid()

    const userData = {
        password,
        phone: normalizedPhone,
        isPhoneVerified: Boolean(normalizedPhone),
        type: userType,
        name: userInfo.name,
        sender,
        dv,
    }

    const user = await User.create(context, userData)

    return await linkUser(context, user, userInfo)
}

const syncUser = async ({ context, userInfo, userType }) => {
    const userIdentities = await UserExternalIdentity.getAll(context, {
        identityType: TELEGRAM_IDP_TYPE,
        identityId: String(userInfo.userId),
        deletedAt: null,
    }, 'id user { id }')

    if (userIdentities.length > 0) {
        const [identity] = userIdentities
        const { user: { id } } = identity
        return { id }
    }
    const payload = { phone: normalizePhone(userInfo.phoneNumber), type: userType, deletedAt: null }
    console.error(payload)
    const existed = await User.getOne(context, {
        phone: normalizePhone(userInfo.phoneNumber), type: userType, deletedAt: null,
    }, 'id dv')

    if (existed) {
        await User.update(context, existed.id, { dv: existed.dv, sender, isPhoneVerified: true })
        try {
            return await linkUser(context, existed, userInfo)
        } catch (error) {
            console.error(error)
            throw error
        }
    }

    return await registerUser(context, userInfo, userType)
}

module.exports = {
    syncUser,
}