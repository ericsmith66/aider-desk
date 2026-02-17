
import { Store } from './src/main/store/store';
import { AIDER_DESK_DATA_DIR } from './src/main/constants';

async function check() {
    const store = new Store();
    await store.init(AIDER_DESK_DATA_DIR);
    console.log(JSON.stringify(store.getSettings().server, null, 2));
}

check();
